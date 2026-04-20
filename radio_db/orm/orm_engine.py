from enum import IntEnum
from typing import Optional

import sqlalchemy
from dataclasses import dataclass

from orm.orm_models import Base

class DatabaseType(IntEnum):
    Postgresql = 0
    MySQL = 1
    Oracle = 2
    SQLite = 3

@dataclass
class DatabaseConnectionParameters:
    Type: DatabaseType
    Database: str
    Host: Optional[str] = None
    Port: Optional[int] = None
    User: Optional[str] = None
    Password: Optional[str] = None

def create(db_param: DatabaseConnectionParameters) -> sqlalchemy.Engine | None:
    engine: sqlalchemy.Engine | None = None
    if db_param.Type == DatabaseType.SQLite:
        engine = sqlalchemy.create_engine(f"sqlite:///{db_param.Database}")
    elif db_param.Type == DatabaseType.Postgresql:
        engine = sqlalchemy.create_engine(f"postgresql+psycopg2://{db_param.User}:{db_param.Password}@{db_param.Host}:{db_param.Port}/{db_param.Database}")
    elif db_param.Type == DatabaseType.MySQL:
        engine = sqlalchemy.create_engine(f"mysql+mysqlconnector://{db_param.User}:{db_param.Password}@{db_param.Host}:{db_param.Port}/{db_param.Database}")
    elif db_param.Type == DatabaseType.Oracle:
        engine = sqlalchemy.create_engine(f"oracle+oracledb://{db_param.User}:{db_param.Password}@{db_param.Host}:{db_param.Port}/?service_name={db_param.Database}")

    if engine is None:
        return None

    engine.connect()
    Base.metadata.create_all(engine)
    return engine