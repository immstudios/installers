DROP TABLE IF EXISTS public.settings;
DROP TABLE IF EXISTS public.items;
DROP TABLE IF EXISTS public.events;
DROP TABLE IF EXISTS public.bins;
DROP TABLE IF EXISTS public.assets;
DROP TABLE IF EXISTS public.folders;
DROP TABLE IF EXISTS public.origins;


CREATE TABLE public.settings (
        key VARCHAR(255) NOT NULL,
        value VARCHAR(255),
        CONSTRAINT settings_pkey PRIMARY KEY (key)
    );

CREATE TABLE public.folders (
        id SERIAL NOT NULL,
        title VARCHAR(255),
        color INTEGER,
        meta_set JSONB,
        CONSTRAINT folders_pkey PRIMARY KEY (id)
    );

CREATE TABLE public.origins (
        id SERIAL NOT NULL,
        title VARCHAR(255),
        CONSTRAINT origins_pkey PRIMARY KEY (id)
    );

CREATE TABLE public.assets (
        id SERIAL NOT NULL,
        id_folder INTEGER REFERENCES public.folders(id),
        id_origin INTEGER REFERENCES public.origins(id),
        status INTEGER NOT NULL,
        metadata JSONB,
        CONSTRAINT assets_pkey PRIMARY KEY (id)
    );

CREATE TABLE public.bins(
        id SERIAL NOT NULL,
        bin_type INTEGER NOT NULL,
        metadata JSONB,
        CONSTRAINT bins_pkey PRIMARY KEY (id)
    );

CREATE TABLE public.events(
        id SERIAL NOT NULL,
        event_type INTEGER NOT NULL,
        metadata JSONB,
        CONSTRAINT events_pkey PRIMARY KEY (id)
    );

CREATE TABLE public.items(
        id SERIAL NOT NULL,
        id_bin INTEGER REFERENCES public.bins(id),
        id_asset INTEGER REFERENCES public.assets(id),
        position INTEGER NOT NULL,
        metadata JSONB,
        CONSTRAINT items_pkey PRIMARY KEY (id)
    );
