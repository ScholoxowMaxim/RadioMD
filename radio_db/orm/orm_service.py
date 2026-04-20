from typing import Any
from sqlalchemy import Engine
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session, subqueryload
from orm.orm_engine import DatabaseConnectionParameters, create
from orm.orm_models import User, RadioStation, Favorite, Ganre

# Базовый класс
class Base:
    def __init__(self, engine: Engine):
        self._engine = engine
        self.List = []

    def read(self):
        pass

    def add(self, data):
        pass

    def update(self, data):
        pass

    def delete(self, data: Any | None):
        pass


class Users(Base):
    def add(self, user: User) -> (int, str | None):
        try:
            with Session(self._engine) as session:
                with session.begin():
                    session.add(user)
                    session.flush()
                    return user.id, None
        except SQLAlchemyError as e:
            print(f"Ошибка при добавлении пользователя: {e}")
            return -1, str(e)

    def read(self) -> (list[User], str | None):
        try:
            with Session(self._engine) as session:
                self.List = session.query(User).all()
                return self.List, None
        except SQLAlchemyError as e:
            print(f"Ошибка при чтении пользователей: {e}")
            return [], str(e)

    def update(self, user: User) -> str | None:
        try:
            with Session(self._engine) as session:
                with session.begin():
                    session.query(User).filter(User.id == user.id).update({
                        User.name: user.name,
                        User.date_of_birth: user.date_of_birth,
                        User.email: user.email,
                        User.password_hash: user.password_hash,
                        User.date_created: user.date_created
                    })
                    session.commit()
                    return None
        except SQLAlchemyError as e:
            print(f"Ошибка при обновлении пользователя: {e}")
            return str(e)

    def delete(self, user: User) -> str | None:
        try:
            with Session(self._engine) as session:
                with session.begin():
                    if not isinstance(user, User):
                        session.query(User).delete()
                    else:
                        session.query(User).filter(User.id == user.id).delete()
                    session.commit()
                    return None
        except SQLAlchemyError as e:
            print(f"Ошибка при удалении пользователя: {e}")
            return str(e)


class RadioStations(Base):
    def add(self, radio_station: RadioStation) -> (int, str | None):
        try:
            with Session(self._engine) as session:
                with session.begin():
                    session.add(radio_station)
                    session.flush()
                    return radio_station.id, None
        except SQLAlchemyError as e:
            print(f"Ошибка при добавлении радиостанции: {e}")
            return -1, str(e)

    def read(self) -> (list[RadioStation], str | None):
        try:
            with Session(self._engine) as session:
                # Исправлено: используем genre (связь), а не ganre
                self.List = session.query(RadioStation).options(subqueryload(RadioStation.genre)).all()
                return self.List, None
        except SQLAlchemyError as e:
            print(f"Ошибка при чтении радиостанций: {e}")
            return [], str(e)

    def update(self, radio_station: RadioStation) -> str | None:
        try:
            with Session(self._engine) as session:
                with session.begin():
                    session.query(RadioStation).filter(RadioStation.id == radio_station.id).update({
                        RadioStation.name: radio_station.name,
                        RadioStation.stream_url: radio_station.stream_url,
                        RadioStation.logo_url: radio_station.logo_url,
                        RadioStation.ganre_id: radio_station.ganre_id
                    })
                    session.commit()
                    return None
        except SQLAlchemyError as e:
            print(f"Ошибка при обновлении радиостанции: {e}")
            return str(e)

    def delete(self, radio_station: RadioStation) -> str | None:
        try:
            with Session(self._engine) as session:
                with session.begin():
                    if not isinstance(radio_station, RadioStation):
                        session.query(RadioStation).delete()
                    else:
                        session.query(RadioStation).filter(RadioStation.id == radio_station.id).delete()
                    session.commit()
                    return None
        except SQLAlchemyError as e:
            print(f"Ошибка при удалении радиостанции: {e}")
            return str(e)


class Favorites(Base):
    def add(self, favorite: Favorite) -> (int, str | None):
        try:
            with Session(self._engine) as session:
                with session.begin():
                    session.add(favorite)
                    session.flush()
                    return favorite.id, None
        except SQLAlchemyError as e:
            print(f"Ошибка при добавлении избранного: {e}")
            return -1, str(e)

    def read(self) -> (list[Favorite], str | None):
        try:
            with Session(self._engine) as session:
                self.List = session.query(Favorite).options(subqueryload(Favorite.user), subqueryload(Favorite.radiostation)).all()
                return self.List, None
        except SQLAlchemyError as e:
            print(f"Ошибка при чтении избранного: {e}")
            return [], str(e)

    def update(self, favorite: Favorite) -> str | None:
        try:
            with Session(self._engine) as session:
                with session.begin():
                    session.query(Favorite).filter(Favorite.id == favorite.id).update({
                        Favorite.users_id: favorite.users_id,
                        Favorite.radiostations_id: favorite.radiostations_id,
                        Favorite.date_added: favorite.date_added
                    })
                    session.commit()
                    return None
        except SQLAlchemyError as e:
            print(f"Ошибка при обновлении избранного: {e}")
            return str(e)

    def delete(self, favorite: Favorite) -> str | None:
        try:
            with Session(self._engine) as session:
                with session.begin():
                    if not isinstance(favorite, Favorite):
                        session.query(Favorite).delete()
                    else:
                        session.query(Favorite).filter(Favorite.id == favorite.id).delete()
                    session.commit()
                    return None
        except SQLAlchemyError as e:
            print(f"Ошибка при удалении избранного: {e}")
            return str(e)


class Ganres(Base):
    def add(self, ganre: Ganre) -> (int, str | None):
        try:
            with Session(self._engine) as session:
                with session.begin():
                    session.add(ganre)
                    session.flush()
                    return ganre.id, None
        except SQLAlchemyError as e:
            print(f"Ошибка при добавлении жанра: {e}")
            return -1, str(e)

    def read(self) -> (list[Ganre], str | None):
        try:
            with Session(self._engine) as session:
                self.List = session.query(Ganre).all()
                return self.List, None
        except SQLAlchemyError as e:
            print(f"Ошибка при чтении жанров: {e}")
            return [], str(e)

    def update(self, ganre: Ganre) -> str | None:
        try:
            with Session(self._engine) as session:
                with session.begin():
                    session.query(Ganre).filter(Ganre.id == ganre.id).update({
                        Ganre.name: ganre.name
                    })
                    session.commit()
                    return None
        except SQLAlchemyError as e:
            print(f"Ошибка при обновлении жанра: {e}")
            return str(e)

    def delete(self, ganre: Ganre) -> str | None:
        try:
            with Session(self._engine) as session:
                with session.begin():
                    if not isinstance(ganre, Ganre):
                        session.query(Ganre).delete()
                    else:
                        session.query(Ganre).filter(Ganre.id == ganre.id).delete()
                    session.commit()
                    return None
        except SQLAlchemyError as e:
            print(f"Ошибка при удалении жанра: {e}")
            return str(e)


class Service:
    def __init__(self, params: DatabaseConnectionParameters):
        self.params = params
        self._engine = create(params)

        self.Users = Users(self._engine)
        self.RadioStations = RadioStations(self._engine)
        self.Favorites = Favorites(self._engine)
        self.Ganres = Ganres(self._engine)