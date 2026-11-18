-- À remplacer / compléter par le schéma de la personne qui gère la base.
CREATE TABLE IF NOT EXISTS sessions (
  id          SERIAL PRIMARY KEY,
  room_code   VARCHAR(8)   NOT NULL,
  port        INTEGER      NOT NULL,
  started_at  TIMESTAMPTZ  NOT NULL,
  ended_at    TIMESTAMPTZ  NOT NULL,
  duration_s  INTEGER      NOT NULL CHECK (duration_s >= 0),
  max_players SMALLINT     NOT NULL DEFAULT 2
);
