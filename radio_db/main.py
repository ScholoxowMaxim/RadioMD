import sys
from pathlib import Path

sys.path.append(str(Path(__file__).parent))

from orm.orm_engine import DatabaseConnectionParameters, DatabaseType
from orm.orm_service import Service

def main():
    db_params = DatabaseConnectionParameters(
        Type=DatabaseType.Postgresql,
        Database="radio_db",
        Host="localhost",
        Port=5432,
        User="postgres",
        Password="gg52_GG25"
    )

    print("Создание таблиц в PostgreSQL...")
    try:
        service = Service(db_params)
        print("Таблицы успешно созданы.")
    except Exception as e:
        print(f"Ошибка: {e}")

if __name__ == "__main__":
    main()