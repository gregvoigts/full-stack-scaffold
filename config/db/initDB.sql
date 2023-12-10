-- GET AND SAVE ENV VARS
\set api_user `echo "$POSTGRES_API_USER"`
\set api_password `echo "$POSTGRES_API_PASSWORD"`

-- CREATE DATABASE

CREATE DATABASE ptv WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE = 'en_US.utf8';
ALTER DATABASE ptv OWNER TO admin;

-- PERMISSIONS

CREATE USER :api_user WITH PASSWORD :'api_password';
REVOKE ALL ON DATABASE ptv FROM :api_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO :api_user;
GRANT INSERT ON ALL TABLES IN SCHEMA public TO :api_user;

\connect ptv

-- load uuid extension

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;

DROP TABLE IF EXISTS public.sessions CASCADE;

CREATE TABLE IF NOT EXISTS public.sessions
(
    id uuid NOT NULL PRIMARY KEY,
    "electionPeriod" integer NOT NULL,
    "sessionNumber" integer NOT NULL,
    "sessionStart" date NOT NULL,
    "sessionEnd" date NOT NULL,
    "numberOfDays" integer NOT NULL,
    "showTimes" boolean NOT NULL,

    UNIQUE ("electionPeriod","sessionNumber")  -- make sure session information is unique
);


DROP TABLE IF EXISTS public.meetings CASCADE;

CREATE TABLE IF NOT EXISTS public.meetings
(
    id uuid NOT NULL PRIMARY KEY,
    "meetingDate" date NOT NULL,
    "meetingNumber" integer NOT NULL,
    "fkSession" uuid NOT NULL,

    UNIQUE ("meetingDate"),  -- make sure only one meeting at a day

    CONSTRAINT meeting_session_fkey
        FOREIGN KEY("fkSession") 
        REFERENCES public.sessions(id)
            ON DELETE CASCADE
            ON UPDATE CASCADE
);
CREATE INDEX ON public.meetings ("fkSession");

DROP TABLE IF EXISTS public.items CASCADE;

CREATE TABLE IF NOT EXISTS public.items
(
    id uuid NOT NULL PRIMARY KEY,
    rze_id char(24) NOT NULL,
    "itemNumber" real NOT NULL,
    "itemBeginning" time NOT NULL,
    "itemDuration" integer NOT NULL,
    "endTime" time,
    done boolean NOT NULL,
    "fkMeeting" uuid NOT NULL,
    "updatedAt" timestamp NOT NULL,
    "togetherStatus" text NOT NULL,
    "visible" boolean NOT NULL,
    "itemType" text NOT NULL,
    hint text,

    UNIQUE("itemNumber","fkMeeting"), -- make sure itemNumber is unique during one meeting

    CONSTRAINT item_meeting_fkey
        FOREIGN KEY("fkMeeting") 
        REFERENCES public.meetings(id)
            ON DELETE CASCADE
            ON UPDATE CASCADE
);
CREATE INDEX ON public.items ("fkMeeting");

DROP TABLE IF EXISTS public.videos CASCADE;

CREATE TABLE IF NOT EXISTS public.videos
(  
    "streamFileName" text NOT NULL PRIMARY KEY,
    "startTime" timestamp,
    "offset" integer NOT NULL DEFAULT 0
);

DROP TABLE IF EXISTS public.subjects CASCADE;

CREATE TABLE IF NOT EXISTS public.subjects
(
    id uuid NOT NULL PRIMARY KEY,
    rze_id char(24) NOT NULL,
    "subjectNumber" integer NOT NULL,
    "fkItem" uuid NOT NULL,
    "itemPostfix" text,
    title text NOT NULL,
    "consultationType" text NOT NULL,
    "consultationTypeKZ" smallint NOT NULL,
    "subjectArt" text,
    "subjectVisible" integer NOT NULL,
    "applicant" text,
    "applicantText" text,
    "incomingPrint" text,
    "incomingPrintLink" text,
    "rejects" text,
    "rejectsdrs" text,
    "rejectsdrsLink" text,
    "rejectRecommendation" text,
    "updatedAt" timestamp NOT NULL,
    "itemStartTimeInStreamSecs" real,
    "itemStopTimeInStreamSecs" real,    
    "streamFileName" text,
    "vttFile" text,
    "vttOffset" real,
    "visible" boolean NOT NULL,
    ts tsvector GENERATED ALWAYS AS (to_tsvector('german', title)) STORED,

    UNIQUE("subjectNumber","fkItem"), -- make sure itemPostfix is unique in one Item

    CONSTRAINT subject_item_fkey
        FOREIGN KEY("fkItem") 
        REFERENCES public.items(id)
            ON DELETE CASCADE
            ON UPDATE CASCADE,

    CONSTRAINT subject_video_fkey
        FOREIGN KEY("streamFileName") 
        REFERENCES public.videos("streamFileName")
            ON DELETE SET NULL
            ON UPDATE CASCADE
);
CREATE INDEX ts_idx ON public.subjects USING GIN (ts);
CREATE INDEX ON public.subjects ("fkItem");


DROP TABLE IF EXISTS public."speakerTimings" CASCADE;

CREATE TABLE IF NOT EXISTS public."speakerTimings"
(
    id uuid NOT NULL PRIMARY KEY,
    rze_id char(24) NOT NULL,
    abg_id integer NOT NULL,
    surname text NOT NULL,
    name text NOT NULL,
    "speakerTitle" text,
    fraktion text,
    "startTimeInStreamSecs" real NOT NULL,
    "stopTimeInStreamSecs" real NOT NULL,
    "speechType" text NOT NULL,
    function text,
    "updatedAt" timestamp NOT NULL
);

DROP TABLE IF EXISTS public."subjects_x_speakerTimings";

CREATE TABLE IF NOT EXISTS public."subjects_x_speakerTimings"
(
    "fkSubject" uuid NOT NULL REFERENCES subjects (id) ON UPDATE CASCADE ON DELETE CASCADE,
    "fkSpeakerTiming" uuid NOT NULL REFERENCES "speakerTimings" (id) ON UPDATE CASCADE ON DELETE CASCADE,

    PRIMARY Key ("fkSubject","fkSpeakerTiming")
);

--Trigger and Function to delete speakerTimings without any subjects
DROP FUNCTION IF EXISTS public.clean_speakers() CASCADE;

CREATE FUNCTION public.clean_speakers() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
	DELETE FROM public."speakerTimings" s
    WHERE NOT EXISTS (SELECT NULL FROM public."subjects_x_speakerTimings" WHERE "fkSpeakerTiming" = s.id);
    RETURN NULL;
	END;$$;


ALTER FUNCTION public.clean_speakers() OWNER TO api;


CREATE TRIGGER "cleanSpeakersOnDelete" AFTER DELETE
    ON public."subjects_x_speakerTimings"
EXECUTE PROCEDURE
	clean_speakers();


-- GRANT PERMISSIONS

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.sessions TO :api_user;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.meetings TO :api_user;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.items TO :api_user;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.subjects TO :api_user;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public."speakerTimings" TO :api_user;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public."subjects_x_speakerTimings" TO :api_user;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.videos TO :api_user;
