from sqlalchemy.orm import relationship, declarative_base, mapped_column, Mapped
from sqlalchemy import (Integer, String, ForeignKey, DateTime, UniqueConstraint)

Base = declarative_base()

class User(Base):
    __tablename__ = 'Users'
    id: Mapped[int] = mapped_column(Integer, primary_key=True, name="ID")
    name: Mapped[str] = mapped_column(String, name="Name")
    date_of_birth: Mapped[str] = mapped_column(DateTime, name="DateOfBirth")
    email: Mapped[str] = mapped_column(String, name="Email")
    password_hash: Mapped[str] = mapped_column(String, name="Password")
    date_created: Mapped[str] = mapped_column(DateTime, name="DateCreated")
    
    favorites = relationship('Favorite', back_populates='user', cascade='all, delete-orphan')
    
    def __str__(self):
        return f"[{self.id}] {self.name} | {self.date_of_birth} | {self.email} | {self.password_hash} | {self.date_created}"

class RadioStation(Base):
    __tablename__ = 'Radiostations'
    id: Mapped[int] = mapped_column(Integer, primary_key=True, name="ID")
    name: Mapped[str] = mapped_column(String, name="Name")
    stream_url: Mapped[str] = mapped_column(String, name="StreamUrl")
    logo_url: Mapped[str] = mapped_column(String, name="LogoUrl")
    ganre_id: Mapped[int] = mapped_column(Integer, ForeignKey('Ganres.ID'), name="GanreId")
    
    favorites = relationship('Favorite', back_populates='radiostation', cascade='all, delete-orphan')
    genre = relationship('Ganre', back_populates='radiostations')   # ← связь называется genre

    def __str__(self):
        return f"[{self.id}] {self.name} | {self.stream_url} | {self.logo_url} | {self.ganre_id}"

class Favorite(Base):
    __tablename__ = 'Favorites'
    id: Mapped[int] = mapped_column(Integer, primary_key=True, name="ID")
    users_id: Mapped[int] = mapped_column(Integer, ForeignKey('Users.ID'), nullable=False, name="UsersId")
    radiostations_id: Mapped[int] = mapped_column(Integer, ForeignKey('Radiostations.ID'), nullable=False, name="RadiostationsId")
    date_added: Mapped[str] = mapped_column(DateTime, name="DateAdded")
    
    user = relationship('User', back_populates='favorites')
    radiostation = relationship('RadioStation', back_populates='favorites')
    
    __table_args__ = (
        UniqueConstraint('UsersId', 'RadiostationsId', name='unique_user_radiostation'),
    )
    
    def __str__(self):
        return f"[{self.id}] {self.users_id} | {self.radiostations_id} | {self.date_added}"    

class Ganre(Base):
    __tablename__ = 'Ganres'
    id: Mapped[int] = mapped_column(Integer, primary_key=True, name="ID")
    name: Mapped[str] = mapped_column(String, name="Name", unique=True)
    
    radiostations = relationship('RadioStation', back_populates='genre')
    
    def __str__(self):
        return f"[{self.id}] {self.name}"