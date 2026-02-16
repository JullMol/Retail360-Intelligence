import os
import io
import logging
from datetime import datetime, timedelta
import pandas as pd
from sqlalchemy import create_engine, text


def psql_insert_copy(table, conn, keys, data_iter):
    dbapi_conn = conn.connection
    with dbapi_conn.cursor() as cur:
        s_buf = io.StringIO()
        for row in data_iter:
            cleaned = []
            for x in row:
                if x is None or (isinstance(x, float) and x != x):
                    cleaned.append('')
                else:
                    val = str(x)
                    val = val.replace('\\', '\\\\')
                    val = val.replace('\t', ' ')
                    val = val.replace('\n', ' ')
                    val = val.replace('\r', ' ')
                    cleaned.append(val)
            s_buf.write('\t'.join(cleaned) + '\n')
        s_buf.seek(0)
        cur.copy_from(s_buf, table.name, columns=keys, sep='\t', null='')

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger('retail360')


def get_engine():
    db_url = os.getenv(
        'RETAIL360_DB_URL',
        'postgresql://postgres:rafizzul00@localhost:5432/retail360_dwh'
    )
    return create_engine(db_url)


def validate_dataframe(df, name, required_cols=None):
    report = {
        'table': name,
        'rows': len(df),
        'columns': len(df.columns),
        'null_counts': df.isnull().sum().to_dict(),
        'duplicate_rows': df.duplicated().sum(),
        'status': 'PASS'
    }

    if required_cols:
        missing = [c for c in required_cols if c not in df.columns]
        if missing:
            report['status'] = 'FAIL'
            report['missing_columns'] = missing
            logger.error(f"[{name}] Missing required columns: {missing}")

    total_nulls = df.isnull().sum().sum()
    null_pct = (total_nulls / (len(df) * len(df.columns))) * 100 if len(df) > 0 else 0

    logger.info(f"[{name}] Rows: {report['rows']:,} | Cols: {report['columns']} | "
                f"Duplicates: {report['duplicate_rows']:,} | Null%: {null_pct:.2f}%")

    return report


def log_step(step_name, status='START', detail=''):
    icons = {'START': '>>', 'DONE': '✓', 'FAIL': '✗', 'SKIP': '-'}
    icon = icons.get(status, '?')
    msg = f"[{icon}] {step_name}"
    if detail:
        msg += f" — {detail}"
    if status == 'FAIL':
        logger.error(msg)
    else:
        logger.info(msg)


def generate_dim_date(start_date='2016-01-01', end_date='2019-12-31'):
    start = datetime.strptime(start_date, '%Y-%m-%d')
    end = datetime.strptime(end_date, '%Y-%m-%d')
    dates = []
    current = start

    while current <= end:
        date_key = int(current.strftime('%Y%m%d'))
        fiscal_month = (current.month - 1 + 9) % 12 + 1
        fiscal_quarter = (fiscal_month - 1) // 3 + 1
        fiscal_year = current.year if current.month >= 4 else current.year - 1

        dates.append({
            'date_key': date_key,
            'full_date': current.date(),
            'year': current.year,
            'quarter': (current.month - 1) // 3 + 1,
            'month': current.month,
            'month_name': current.strftime('%B'),
            'day_of_month': current.day,
            'day_of_week': current.isoweekday(),
            'day_name': current.strftime('%A'),
            'week_of_year': int(current.strftime('%W')),
            'is_weekend': current.isoweekday() in (6, 7),
            'fiscal_year': fiscal_year,
            'fiscal_quarter': fiscal_quarter
        })
        current += timedelta(days=1)

    return pd.DataFrame(dates)


def truncate_table(engine, table_name):
    with engine.connect() as conn:
        conn.execute(text(f"TRUNCATE TABLE {table_name} RESTART IDENTITY CASCADE"))
        conn.commit()


def get_row_count(engine, table_name):
    with engine.connect() as conn:
        result = conn.execute(text(f"SELECT COUNT(*) FROM {table_name}"))
        return result.scalar()