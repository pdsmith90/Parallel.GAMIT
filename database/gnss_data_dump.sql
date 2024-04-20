PGDMP  5    5    
            |           gnss_data_osu    13.13     16.2 (Ubuntu 16.2-1.pgdg22.04+1) z    �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            �           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            �           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            �           1262    72706    gnss_data_osu    DATABASE     y   CREATE DATABASE gnss_data_osu WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.UTF-8';
    DROP DATABASE gnss_data_osu;
                gnss_data_osu    false            �           0    0    DATABASE gnss_data_osu    ACL     u   REVOKE CONNECT,TEMPORARY ON DATABASE gnss_data_osu FROM PUBLIC;
GRANT TEMPORARY ON DATABASE gnss_data_osu TO PUBLIC;
                   gnss_data_osu    false    3255                        2615    2200    public    SCHEMA        CREATE SCHEMA public;
    DROP SCHEMA public;
                postgres    false            �           0    0    SCHEMA public    ACL     Q   REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;
                   postgres    false    5            �            1255    86855 5   ecef2neu(numeric, numeric, numeric, numeric, numeric)    FUNCTION     �  CREATE FUNCTION public.ecef2neu(dx numeric, dy numeric, dz numeric, lat numeric, lon numeric) RETURNS double precision[]
    LANGUAGE sql
    AS $_$
select 
array[-sin(radians($4))*cos(radians($5))*$1 - sin(radians($4))*sin(radians($5))*$2 + cos(radians($4))*$3::numeric,
      -sin(radians($5))*$1 + cos(radians($5))*$2::numeric,
      cos(radians($4))*cos(radians($5))*$1 + cos(radians($4))*sin(radians($5))*$2 + sin(radians($4))*$3::numeric];

$_$;
 ]   DROP FUNCTION public.ecef2neu(dx numeric, dy numeric, dz numeric, lat numeric, lon numeric);
       public          postgres    false    5            �            1255    86856 2   fyear(numeric, numeric, numeric, numeric, numeric)    FUNCTION     �  CREATE FUNCTION public.fyear("Year" numeric, "DOY" numeric, "Hour" numeric DEFAULT 12, "Minute" numeric DEFAULT 0, "Second" numeric DEFAULT 0) RETURNS numeric
    LANGUAGE sql
    AS $_$
SELECT CASE 
WHEN isleapyear(cast($1 as integer)) = True  THEN $1 + ($2 + $3/24 + $4/1440 + $5/86400)/366
WHEN isleapyear(cast($1 as integer)) = False THEN $1 + ($2 + $3/24 + $4/1440 + $5/86400)/365
END;

$_$;
 o   DROP FUNCTION public.fyear("Year" numeric, "DOY" numeric, "Hour" numeric, "Minute" numeric, "Second" numeric);
       public          postgres    false    5            �            1255    86857    horizdist(double precision[])    FUNCTION     �   CREATE FUNCTION public.horizdist(neu double precision[]) RETURNS double precision
    LANGUAGE sql
    AS $_$

select 
sqrt(($1)[1]^2 + ($1)[2]^2 + ($1)[3]^2)

$_$;
 8   DROP FUNCTION public.horizdist(neu double precision[]);
       public          postgres    false    5            �            1255    86858    isleapyear(integer)    FUNCTION     �   CREATE FUNCTION public.isleapyear(year integer) RETURNS boolean
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
SELECT ($1 % 4 = 0) AND (($1 % 100 <> 0) or ($1 % 400 = 0))
$_$;
 /   DROP FUNCTION public.isleapyear(year integer);
       public          postgres    false    5            �            1255    86859    stationalias_check()    FUNCTION     i  CREATE FUNCTION public.stationalias_check() RETURNS trigger
    LANGUAGE plpgsql
    AS $$DECLARE
	stnalias BOOLEAN;
BEGIN
SELECT (SELECT "StationCode" FROM stations WHERE "StationCode" = new."StationAlias") IS NULL INTO stnalias;
IF stnalias THEN
    RETURN NEW;
ELSE
	RAISE EXCEPTION 'Invalid station alias: already exists as a station code';
END IF;
END
$$;
 +   DROP FUNCTION public.stationalias_check();
       public          postgres    false    5            �            1255    86860 =   update_station_timespan(character varying, character varying)    FUNCTION     �  CREATE FUNCTION public.update_station_timespan("NetworkCode" character varying, "StationCode" character varying) RETURNS void
    LANGUAGE sql
    AS $_$
update stations set 
"DateStart" = 
    (SELECT MIN("ObservationFYear") as MINN 
     FROM rinex WHERE "NetworkCode" = $1 AND
     "StationCode" = $2),
"DateEnd" = 
    (SELECT MAX("ObservationFYear") as MAXX 
     FROM rinex WHERE "NetworkCode" = $1 AND
     "StationCode" = $2)
WHERE "NetworkCode" = $1 AND "StationCode" = $2
$_$;
 p   DROP FUNCTION public.update_station_timespan("NetworkCode" character varying, "StationCode" character varying);
       public          postgres    false    5            �            1255    86861    update_timespan_trigg()    FUNCTION     G  CREATE FUNCTION public.update_timespan_trigg() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    update stations set 
"DateStart" = 
    (SELECT MIN("ObservationFYear") as MINN 
     FROM rinex 
     WHERE "NetworkCode" = new."NetworkCode" AND
           "StationCode" = new."StationCode"),
"DateEnd" = 
    (SELECT MAX("ObservationFYear") as MAXX 
     FROM rinex 
     WHERE "NetworkCode" = new."NetworkCode" AND
           "StationCode" = new."StationCode")
WHERE "NetworkCode" = new."NetworkCode" 
  AND "StationCode" = new."StationCode";

           RETURN new;
END;
$$;
 .   DROP FUNCTION public.update_timespan_trigg();
       public          postgres    false    5            �            1259    86862    antennas    TABLE        CREATE TABLE public.antennas (
    "AntennaCode" character varying(22) NOT NULL,
    "AntennaDescription" character varying
);
    DROP TABLE public.antennas;
       public         heap    gnss_data_osu    false    5            �            1259    86868 
   apr_coords    TABLE     V  CREATE TABLE public.apr_coords (
    "NetworkCode" character varying NOT NULL,
    "StationCode" character varying NOT NULL,
    "FYear" numeric,
    x numeric,
    y numeric,
    z numeric,
    sn numeric,
    se numeric,
    su numeric,
    "ReferenceFrame" character varying(20),
    "Year" integer NOT NULL,
    "DOY" integer NOT NULL
);
    DROP TABLE public.apr_coords;
       public         heap    gnss_data_osu    false    5            �            1259    86874    aws_sync    TABLE       CREATE TABLE public.aws_sync (
    "NetworkCode" character varying NOT NULL,
    "StationCode" character varying NOT NULL,
    "StationAlias" character varying(4) NOT NULL,
    "Year" numeric NOT NULL,
    "DOY" numeric NOT NULL,
    sync_date timestamp without time zone
);
    DROP TABLE public.aws_sync;
       public         heap    gnss_data_osu    false    5            �            1259    556348    data_source    TABLE     n  CREATE TABLE public.data_source (
    "NetworkCode" character varying(3) NOT NULL,
    "StationCode" character varying(4) NOT NULL,
    try_order numeric NOT NULL,
    protocol character varying NOT NULL,
    fqdn character varying NOT NULL,
    username character varying,
    password character varying,
    path character varying,
    format character varying
);
    DROP TABLE public.data_source;
       public         heap    gnss_data_osu    false    5            �            1259    86880    earthquakes    TABLE     b  CREATE TABLE public.earthquakes (
    date timestamp without time zone NOT NULL,
    lat numeric NOT NULL,
    lon numeric NOT NULL,
    depth numeric,
    mag numeric,
    strike1 numeric,
    dip1 numeric,
    rake1 numeric,
    strike2 numeric,
    dip2 numeric,
    rake2 numeric,
    id character varying(40),
    location character varying(120)
);
    DROP TABLE public.earthquakes;
       public         heap    gnss_data_osu    false    5            �            1259    86886    etm_params_uid_seq    SEQUENCE     {   CREATE SEQUENCE public.etm_params_uid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 )   DROP SEQUENCE public.etm_params_uid_seq;
       public          gnss_data_osu    false    5            �            1259    86888 
   etm_params    TABLE     �  CREATE TABLE public.etm_params (
    "NetworkCode" character varying(3) NOT NULL,
    "StationCode" character varying(4) NOT NULL,
    soln character varying(10) NOT NULL,
    object character varying(10) NOT NULL,
    terms numeric,
    frequencies numeric[],
    jump_type numeric,
    relaxation numeric[],
    "Year" numeric,
    "DOY" numeric,
    action character varying(1),
    uid integer DEFAULT nextval('public.etm_params_uid_seq'::regclass) NOT NULL
);
    DROP TABLE public.etm_params;
       public         heap    gnss_data_osu    false    204    5            �            1259    86895    etmsv2_uid_seq    SEQUENCE     w   CREATE SEQUENCE public.etmsv2_uid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 %   DROP SEQUENCE public.etmsv2_uid_seq;
       public          gnss_data_osu    false    5            �            1259    86897    etms    TABLE       CREATE TABLE public.etms (
    "NetworkCode" character varying(3) NOT NULL,
    "StationCode" character varying(4) NOT NULL,
    soln character varying(10) NOT NULL,
    object character varying(10) NOT NULL,
    t_ref numeric,
    jump_type numeric,
    relaxation numeric[],
    frequencies numeric[],
    params numeric[],
    sigmas numeric[],
    metadata text,
    hash numeric,
    jump_date timestamp without time zone,
    uid integer DEFAULT nextval('public.etmsv2_uid_seq'::regclass) NOT NULL,
    stack character varying(20)
);
    DROP TABLE public.etms;
       public         heap    gnss_data_osu    false    206    5            �            1259    86904    events_event_id_seq    SEQUENCE     |   CREATE SEQUENCE public.events_event_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE public.events_event_id_seq;
       public          gnss_data_osu    false    5            �            1259    86906    events    TABLE     �  CREATE TABLE public.events (
    event_id bigint DEFAULT nextval('public.events_event_id_seq'::regclass) NOT NULL,
    "EventDate" timestamp without time zone DEFAULT now() NOT NULL,
    "EventType" character varying(6),
    "NetworkCode" character varying(3),
    "StationCode" character varying(4),
    "Year" integer,
    "DOY" integer,
    "Description" text,
    stack text,
    module text,
    node text
);
    DROP TABLE public.events;
       public         heap    gnss_data_osu    false    208    5            �            1259    86914    executions_id_seq    SEQUENCE     z   CREATE SEQUENCE public.executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 (   DROP SEQUENCE public.executions_id_seq;
       public          gnss_data_osu    false    5            �            1259    86916 
   executions    TABLE     �   CREATE TABLE public.executions (
    id integer DEFAULT nextval('public.executions_id_seq'::regclass) NOT NULL,
    script character varying(40),
    exec_date timestamp without time zone DEFAULT now()
);
    DROP TABLE public.executions;
       public         heap    gnss_data_osu    false    210    5            �            1259    86921 	   gamit_htc    TABLE     �   CREATE TABLE public.gamit_htc (
    "AntennaCode" character varying(22) NOT NULL,
    "HeightCode" character varying(5) NOT NULL,
    v_offset numeric,
    h_offset numeric
);
    DROP TABLE public.gamit_htc;
       public         heap    gnss_data_osu    false    5            �            1259    86927 
   gamit_soln    TABLE     �  CREATE TABLE public.gamit_soln (
    "NetworkCode" character varying(3) NOT NULL,
    "StationCode" character varying(4) NOT NULL,
    "Project" character varying(20) NOT NULL,
    "Year" numeric NOT NULL,
    "DOY" numeric NOT NULL,
    "FYear" numeric,
    "X" numeric,
    "Y" numeric,
    "Z" numeric,
    sigmax numeric,
    sigmay numeric,
    sigmaz numeric,
    "VarianceFactor" numeric,
    sigmaxy numeric,
    sigmayz numeric,
    sigmaxz numeric
);
    DROP TABLE public.gamit_soln;
       public         heap    gnss_data_osu    false    5            �            1259    86933    gamit_soln_excl    TABLE       CREATE TABLE public.gamit_soln_excl (
    "NetworkCode" character varying(3) NOT NULL,
    "StationCode" character varying(4) NOT NULL,
    "Project" character varying(20) NOT NULL,
    "Year" bigint NOT NULL,
    "DOY" bigint NOT NULL,
    residual numeric
);
 #   DROP TABLE public.gamit_soln_excl;
       public         heap    gnss_data_osu    false    5            �            1259    86939    gamit_stats    TABLE     �  CREATE TABLE public.gamit_stats (
    "Project" character varying(20) NOT NULL,
    subnet numeric NOT NULL,
    "Year" numeric NOT NULL,
    "DOY" numeric NOT NULL,
    "FYear" numeric,
    wl numeric,
    nl numeric,
    nrms numeric,
    relaxed_constrains text,
    max_overconstrained character varying(8),
    updated_apr text,
    iterations numeric,
    node character varying(50),
    execution_time numeric,
    execution_date timestamp without time zone,
    system character(1) NOT NULL
);
    DROP TABLE public.gamit_stats;
       public         heap    gnss_data_osu    false    5            �            1259    86945    gamit_subnets    TABLE     !  CREATE TABLE public.gamit_subnets (
    "Project" character varying(20) NOT NULL,
    subnet numeric NOT NULL,
    "Year" numeric NOT NULL,
    "DOY" numeric NOT NULL,
    centroid numeric[],
    stations character varying[],
    alias character varying[],
    ties character varying[]
);
 !   DROP TABLE public.gamit_subnets;
       public         heap    gnss_data_osu    false    5            �            1259    86951 	   gamit_ztd    TABLE     ^  CREATE TABLE public.gamit_ztd (
    "NetworkCode" character varying(3) NOT NULL,
    "StationCode" character varying(4) NOT NULL,
    "Date" timestamp without time zone NOT NULL,
    "Project" character varying(20) NOT NULL,
    "Year" numeric NOT NULL,
    "DOY" numeric NOT NULL,
    "ZTD" numeric NOT NULL,
    model numeric,
    sigma numeric
);
    DROP TABLE public.gamit_ztd;
       public         heap    gnss_data_osu    false    5            �            1259    86957    keys    TABLE     �   CREATE TABLE public.keys (
    "KeyCode" character varying(7) NOT NULL,
    "TotalChars" integer,
    rinex_col_out character varying,
    rinex_col_in character varying(60),
    isnumeric bit(1)
);
    DROP TABLE public.keys;
       public         heap    gnss_data_osu    false    5            �            1259    86963    locks    TABLE     �   CREATE TABLE public.locks (
    filename text NOT NULL,
    "NetworkCode" character varying(3),
    "StationCode" character varying(4)
);
    DROP TABLE public.locks;
       public         heap    gnss_data_osu    false    5            �            1259    86969    networks    TABLE     t   CREATE TABLE public.networks (
    "NetworkCode" character varying NOT NULL,
    "NetworkName" character varying
);
    DROP TABLE public.networks;
       public         heap    gnss_data_osu    false    5            �            1259    86975    ppp_soln    TABLE     �  CREATE TABLE public.ppp_soln (
    "NetworkCode" character varying NOT NULL,
    "StationCode" character varying NOT NULL,
    "X" numeric(12,4),
    "Y" numeric(12,4),
    "Z" numeric(12,4),
    "Year" numeric NOT NULL,
    "DOY" numeric NOT NULL,
    "ReferenceFrame" character varying(20) NOT NULL,
    sigmax numeric,
    sigmay numeric,
    sigmaz numeric,
    sigmaxy numeric,
    sigmaxz numeric,
    sigmayz numeric,
    hash integer
);
    DROP TABLE public.ppp_soln;
       public         heap    gnss_data_osu    false    5            �            1259    86981    ppp_soln_excl    TABLE     �   CREATE TABLE public.ppp_soln_excl (
    "NetworkCode" character varying(3) NOT NULL,
    "StationCode" character varying(4) NOT NULL,
    "Year" numeric NOT NULL,
    "DOY" numeric NOT NULL
);
 !   DROP TABLE public.ppp_soln_excl;
       public         heap    gnss_data_osu    false    5            �            1259    86987 	   receivers    TABLE     �   CREATE TABLE public.receivers (
    "ReceiverCode" character varying(22) NOT NULL,
    "ReceiverDescription" character varying(22)
);
    DROP TABLE public.receivers;
       public         heap    gnss_data_osu    false    5            �            1259    86990    rinex    TABLE     1  CREATE TABLE public.rinex (
    "NetworkCode" character varying NOT NULL,
    "StationCode" character varying NOT NULL,
    "ObservationYear" numeric NOT NULL,
    "ObservationMonth" numeric NOT NULL,
    "ObservationDay" numeric NOT NULL,
    "ObservationDOY" numeric NOT NULL,
    "ObservationFYear" numeric NOT NULL,
    "ObservationSTime" timestamp without time zone,
    "ObservationETime" timestamp without time zone,
    "ReceiverType" character varying(20),
    "ReceiverSerial" character varying(20),
    "ReceiverFw" character varying(20),
    "AntennaType" character varying(20),
    "AntennaSerial" character varying(20),
    "AntennaDome" character varying(20),
    "Filename" character varying(50),
    "Interval" numeric NOT NULL,
    "AntennaOffset" numeric,
    "Completion" numeric(7,3) NOT NULL
);
    DROP TABLE public.rinex;
       public         heap    gnss_data_osu    false    5            �            1259    86996 
   rinex_proc    VIEW       CREATE VIEW public.rinex_proc AS
 SELECT rnx."NetworkCode",
    rnx."StationCode",
    rnx."ObservationYear",
    rnx."ObservationMonth",
    rnx."ObservationDay",
    rnx."ObservationDOY",
    rnx."ObservationFYear",
    rnx."ObservationSTime",
    rnx."ObservationETime",
    rnx."ReceiverType",
    rnx."ReceiverSerial",
    rnx."ReceiverFw",
    rnx."AntennaType",
    rnx."AntennaSerial",
    rnx."AntennaDome",
    rnx."Filename",
    rnx."Interval",
    rnx."AntennaOffset",
    rnx."Completion",
    rnx."mI"
   FROM ( SELECT aa."NetworkCode",
            aa."StationCode",
            aa."ObservationYear",
            aa."ObservationMonth",
            aa."ObservationDay",
            aa."ObservationDOY",
            aa."ObservationFYear",
            aa."ObservationSTime",
            aa."ObservationETime",
            aa."ReceiverType",
            aa."ReceiverSerial",
            aa."ReceiverFw",
            aa."AntennaType",
            aa."AntennaSerial",
            aa."AntennaDome",
            aa."Filename",
            aa."Interval",
            aa."AntennaOffset",
            aa."Completion",
            min(aa."Interval") OVER (PARTITION BY aa."NetworkCode", aa."StationCode", aa."ObservationYear", aa."ObservationDOY") AS "mI"
           FROM (public.rinex aa
             LEFT JOIN public.rinex bb ON ((((aa."NetworkCode")::text = (bb."NetworkCode")::text) AND ((aa."StationCode")::text = (bb."StationCode")::text) AND (aa."ObservationYear" = bb."ObservationYear") AND (aa."ObservationDOY" = bb."ObservationDOY") AND (aa."Completion" < bb."Completion"))))
          WHERE (bb."NetworkCode" IS NULL)
          ORDER BY aa."NetworkCode", aa."StationCode", aa."ObservationYear", aa."ObservationDOY", aa."Interval", aa."Completion") rnx
  WHERE (rnx."Interval" = rnx."mI");
    DROP VIEW public.rinex_proc;
       public          gnss_data_osu    false    224    224    224    224    224    224    224    224    224    224    224    224    224    224    224    224    224    224    224    5            �            1259    87001    rinex_sources_info    TABLE       CREATE TABLE public.rinex_sources_info (
    name character varying(20) NOT NULL,
    fqdn character varying NOT NULL,
    protocol character varying NOT NULL,
    username character varying,
    password character varying,
    path character varying,
    format character varying
);
 &   DROP TABLE public.rinex_sources_info;
       public         heap    gnss_data_osu    false    5            �            1259    87007    rinex_tank_struct    TABLE     l   CREATE TABLE public.rinex_tank_struct (
    "Level" integer NOT NULL,
    "KeyCode" character varying(7)
);
 %   DROP TABLE public.rinex_tank_struct;
       public         heap    gnss_data_osu    false    5            �            1259    556361    sources_formats    TABLE     O   CREATE TABLE public.sources_formats (
    format character varying NOT NULL
);
 #   DROP TABLE public.sources_formats;
       public         heap    gnss_data_osu    false    5            �            1259    556371    sources_servers    TABLE     �  CREATE TABLE public.sources_servers (
    server_id integer NOT NULL,
    protocol character varying NOT NULL,
    fqdn character varying NOT NULL,
    username character varying,
    password character varying,
    path character varying,
    format character varying DEFAULT 'DEFAULT_FORMAT'::character varying NOT NULL,
    CONSTRAINT sources_servers_protocol_check CHECK (((protocol)::text = ANY ((ARRAY['ftp'::character varying, 'http'::character varying, 'sftp'::character varying, 'https'::character varying, 'ftpa'::character varying, 'FTP'::character varying, 'HTTP'::character varying, 'SFTP'::character varying, 'HTTPS'::character varying, 'FTPA'::character varying])::text[])))
);
 #   DROP TABLE public.sources_servers;
       public         heap    gnss_data_osu    false    5            �            1259    556369    sources_servers_server_id_seq    SEQUENCE     �   ALTER TABLE public.sources_servers ALTER COLUMN server_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.sources_servers_server_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
            public          gnss_data_osu    false    235    5            �            1259    556386    sources_stations    TABLE       CREATE TABLE public.sources_stations (
    "NetworkCode" character varying(3) NOT NULL,
    "StationCode" character varying(4) NOT NULL,
    try_order smallint DEFAULT 1 NOT NULL,
    server_id integer NOT NULL,
    path character varying,
    format character varying
);
 $   DROP TABLE public.sources_stations;
       public         heap    gnss_data_osu    false    5            �            1259    87010    stacks    TABLE     �  CREATE TABLE public.stacks (
    "NetworkCode" character varying(3) NOT NULL,
    "StationCode" character varying(4) NOT NULL,
    "Project" character varying(20) NOT NULL,
    "Year" numeric NOT NULL,
    "DOY" numeric NOT NULL,
    "FYear" numeric,
    "X" numeric,
    "Y" numeric,
    "Z" numeric,
    sigmax numeric,
    sigmay numeric,
    sigmaz numeric,
    "VarianceFactor" numeric,
    sigmaxy numeric,
    sigmayz numeric,
    sigmaxz numeric,
    name character varying(20) NOT NULL
);
    DROP TABLE public.stacks;
       public         heap    gnss_data_osu    false    5            �            1259    87016    stationalias    TABLE     �   CREATE TABLE public.stationalias (
    "NetworkCode" character varying(3) NOT NULL,
    "StationCode" character varying(4) NOT NULL,
    "StationAlias" character varying(4) NOT NULL
);
     DROP TABLE public.stationalias;
       public         heap    gnss_data_osu    false    5            �            1259    87019    stationinfo    TABLE     �  CREATE TABLE public.stationinfo (
    "NetworkCode" character varying(3) NOT NULL,
    "StationCode" character varying(4) NOT NULL,
    "ReceiverCode" character varying(22) NOT NULL,
    "ReceiverSerial" character varying(22),
    "ReceiverFirmware" character varying(10),
    "AntennaCode" character varying(22) NOT NULL,
    "AntennaSerial" character varying(20),
    "AntennaHeight" numeric(6,4),
    "AntennaNorth" numeric(12,4),
    "AntennaEast" numeric(12,4),
    "HeightCode" character varying,
    "RadomeCode" character varying(7) NOT NULL,
    "DateStart" timestamp without time zone NOT NULL,
    "DateEnd" timestamp without time zone,
    "ReceiverVers" character varying(22),
    "Comments" text
);
    DROP TABLE public.stationinfo;
       public         heap    gnss_data_osu    false    5            �            1259    87025    stations    TABLE     �  CREATE TABLE public.stations (
    "NetworkCode" character varying(3) NOT NULL,
    "StationCode" character varying(4) NOT NULL,
    "StationName" character varying(40),
    "DateStart" numeric(7,3),
    "DateEnd" numeric(7,3),
    auto_x numeric,
    auto_y numeric,
    auto_z numeric,
    "Harpos_coeff_otl" text,
    lat numeric,
    lon numeric,
    height numeric,
    max_dist numeric,
    dome character varying(9),
    country_code character varying(3),
    marker integer
);
    DROP TABLE public.stations;
       public         heap    gnss_data_osu    false    5            �           2606    522474    antennas antennas_pkey 
   CONSTRAINT     _   ALTER TABLE ONLY public.antennas
    ADD CONSTRAINT antennas_pkey PRIMARY KEY ("AntennaCode");
 @   ALTER TABLE ONLY public.antennas DROP CONSTRAINT antennas_pkey;
       public            gnss_data_osu    false    200            �           2606    522476    apr_coords apr_coords_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.apr_coords
    ADD CONSTRAINT apr_coords_pkey PRIMARY KEY ("NetworkCode", "StationCode", "Year", "DOY");
 D   ALTER TABLE ONLY public.apr_coords DROP CONSTRAINT apr_coords_pkey;
       public            gnss_data_osu    false    201    201    201    201            �           2606    522478    aws_sync aws_sync_pkey 
   CONSTRAINT     }   ALTER TABLE ONLY public.aws_sync
    ADD CONSTRAINT aws_sync_pkey PRIMARY KEY ("NetworkCode", "StationCode", "Year", "DOY");
 @   ALTER TABLE ONLY public.aws_sync DROP CONSTRAINT aws_sync_pkey;
       public            gnss_data_osu    false    202    202    202    202                       2606    556355    data_source data_source_pkey 
   CONSTRAINT        ALTER TABLE ONLY public.data_source
    ADD CONSTRAINT data_source_pkey PRIMARY KEY ("NetworkCode", "StationCode", try_order);
 F   ALTER TABLE ONLY public.data_source DROP CONSTRAINT data_source_pkey;
       public            gnss_data_osu    false    232    232    232            �           2606    522479    stationinfo date_chk    CHECK CONSTRAINT     h   ALTER TABLE public.stationinfo
    ADD CONSTRAINT date_chk CHECK (("DateEnd" > "DateStart")) NOT VALID;
 9   ALTER TABLE public.stationinfo DROP CONSTRAINT date_chk;
       public          gnss_data_osu    false    230    230    230    230            �           2606    522481    earthquakes earthquakes_pkey 
   CONSTRAINT     f   ALTER TABLE ONLY public.earthquakes
    ADD CONSTRAINT earthquakes_pkey PRIMARY KEY (date, lat, lon);
 F   ALTER TABLE ONLY public.earthquakes DROP CONSTRAINT earthquakes_pkey;
       public            gnss_data_osu    false    203    203    203            �           2606    522483    etm_params etm_params_pkey 
   CONSTRAINT     Y   ALTER TABLE ONLY public.etm_params
    ADD CONSTRAINT etm_params_pkey PRIMARY KEY (uid);
 D   ALTER TABLE ONLY public.etm_params DROP CONSTRAINT etm_params_pkey;
       public            gnss_data_osu    false    205            �           2606    522485    etms etmsv2_pkey 
   CONSTRAINT     O   ALTER TABLE ONLY public.etms
    ADD CONSTRAINT etmsv2_pkey PRIMARY KEY (uid);
 :   ALTER TABLE ONLY public.etms DROP CONSTRAINT etmsv2_pkey;
       public            gnss_data_osu    false    207            �           2606    522487    events events_pkey 
   CONSTRAINT     c   ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (event_id, "EventDate");
 <   ALTER TABLE ONLY public.events DROP CONSTRAINT events_pkey;
       public            gnss_data_osu    false    209    209            �           2606    522489    gamit_htc gamit_htc_pkey 
   CONSTRAINT     o   ALTER TABLE ONLY public.gamit_htc
    ADD CONSTRAINT gamit_htc_pkey PRIMARY KEY ("AntennaCode", "HeightCode");
 B   ALTER TABLE ONLY public.gamit_htc DROP CONSTRAINT gamit_htc_pkey;
       public            gnss_data_osu    false    212    212            �           2606    522491 $   gamit_soln_excl gamit_soln_excl_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.gamit_soln_excl
    ADD CONSTRAINT gamit_soln_excl_pkey PRIMARY KEY ("NetworkCode", "StationCode", "Project", "Year", "DOY");
 N   ALTER TABLE ONLY public.gamit_soln_excl DROP CONSTRAINT gamit_soln_excl_pkey;
       public            gnss_data_osu    false    214    214    214    214    214            �           2606    522493    gamit_soln gamit_soln_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.gamit_soln
    ADD CONSTRAINT gamit_soln_pkey PRIMARY KEY ("NetworkCode", "StationCode", "Project", "Year", "DOY");
 D   ALTER TABLE ONLY public.gamit_soln DROP CONSTRAINT gamit_soln_pkey;
       public            gnss_data_osu    false    213    213    213    213    213            �           2606    565050    gamit_stats gamit_stats_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.gamit_stats
    ADD CONSTRAINT gamit_stats_pkey PRIMARY KEY ("Project", subnet, "Year", "DOY", system);
 F   ALTER TABLE ONLY public.gamit_stats DROP CONSTRAINT gamit_stats_pkey;
       public            gnss_data_osu    false    215    215    215    215    215            �           2606    522497     gamit_subnets gamit_subnets_pkey 
   CONSTRAINT     |   ALTER TABLE ONLY public.gamit_subnets
    ADD CONSTRAINT gamit_subnets_pkey PRIMARY KEY ("Project", subnet, "Year", "DOY");
 J   ALTER TABLE ONLY public.gamit_subnets DROP CONSTRAINT gamit_subnets_pkey;
       public            gnss_data_osu    false    216    216    216    216            �           2606    522499    gamit_ztd gamit_ztd_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.gamit_ztd
    ADD CONSTRAINT gamit_ztd_pkey PRIMARY KEY ("NetworkCode", "StationCode", "Date", "Project", "Year", "DOY");
 B   ALTER TABLE ONLY public.gamit_ztd DROP CONSTRAINT gamit_ztd_pkey;
       public            gnss_data_osu    false    217    217    217    217    217    217            �           2606    522509    keys keys_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY public.keys
    ADD CONSTRAINT keys_pkey PRIMARY KEY ("KeyCode");
 8   ALTER TABLE ONLY public.keys DROP CONSTRAINT keys_pkey;
       public            gnss_data_osu    false    218            �           2606    522511    locks locks_pkey 
   CONSTRAINT     T   ALTER TABLE ONLY public.locks
    ADD CONSTRAINT locks_pkey PRIMARY KEY (filename);
 :   ALTER TABLE ONLY public.locks DROP CONSTRAINT locks_pkey;
       public            gnss_data_osu    false    219            �           2606    522513 "   networks networks_NetworkCode_pkey 
   CONSTRAINT     m   ALTER TABLE ONLY public.networks
    ADD CONSTRAINT "networks_NetworkCode_pkey" PRIMARY KEY ("NetworkCode");
 N   ALTER TABLE ONLY public.networks DROP CONSTRAINT "networks_NetworkCode_pkey";
       public            gnss_data_osu    false    220            �           2606    522515     ppp_soln_excl ppp_soln_excl_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.ppp_soln_excl
    ADD CONSTRAINT ppp_soln_excl_pkey PRIMARY KEY ("NetworkCode", "StationCode", "Year", "DOY");
 J   ALTER TABLE ONLY public.ppp_soln_excl DROP CONSTRAINT ppp_soln_excl_pkey;
       public            gnss_data_osu    false    222    222    222    222            �           2606    522517    ppp_soln ppp_soln_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.ppp_soln
    ADD CONSTRAINT ppp_soln_pkey PRIMARY KEY ("NetworkCode", "StationCode", "Year", "DOY", "ReferenceFrame");
 @   ALTER TABLE ONLY public.ppp_soln DROP CONSTRAINT ppp_soln_pkey;
       public            gnss_data_osu    false    221    221    221    221    221            �           2606    522519 %   receivers receivers_ReceiverCode_pkey 
   CONSTRAINT     q   ALTER TABLE ONLY public.receivers
    ADD CONSTRAINT "receivers_ReceiverCode_pkey" PRIMARY KEY ("ReceiverCode");
 Q   ALTER TABLE ONLY public.receivers DROP CONSTRAINT "receivers_ReceiverCode_pkey";
       public            gnss_data_osu    false    223            �           2606    522521    rinex rinex_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.rinex
    ADD CONSTRAINT rinex_pkey PRIMARY KEY ("NetworkCode", "StationCode", "ObservationYear", "ObservationDOY", "Interval", "Completion");
 :   ALTER TABLE ONLY public.rinex DROP CONSTRAINT rinex_pkey;
       public            gnss_data_osu    false    224    224    224    224    224    224            �           2606    522523 *   rinex_sources_info rinex_sources_info_pkey 
   CONSTRAINT     j   ALTER TABLE ONLY public.rinex_sources_info
    ADD CONSTRAINT rinex_sources_info_pkey PRIMARY KEY (name);
 T   ALTER TABLE ONLY public.rinex_sources_info DROP CONSTRAINT rinex_sources_info_pkey;
       public            gnss_data_osu    false    226                        2606    522525 (   rinex_tank_struct rinex_tank_struct_pkey 
   CONSTRAINT     k   ALTER TABLE ONLY public.rinex_tank_struct
    ADD CONSTRAINT rinex_tank_struct_pkey PRIMARY KEY ("Level");
 R   ALTER TABLE ONLY public.rinex_tank_struct DROP CONSTRAINT rinex_tank_struct_pkey;
       public            gnss_data_osu    false    227                       2606    556368 $   sources_formats sources_formats_pkey 
   CONSTRAINT     f   ALTER TABLE ONLY public.sources_formats
    ADD CONSTRAINT sources_formats_pkey PRIMARY KEY (format);
 N   ALTER TABLE ONLY public.sources_formats DROP CONSTRAINT sources_formats_pkey;
       public            gnss_data_osu    false    233                       2606    556380 $   sources_servers sources_servers_pkey 
   CONSTRAINT     i   ALTER TABLE ONLY public.sources_servers
    ADD CONSTRAINT sources_servers_pkey PRIMARY KEY (server_id);
 N   ALTER TABLE ONLY public.sources_servers DROP CONSTRAINT sources_servers_pkey;
       public            gnss_data_osu    false    235                       2606    556394 &   sources_stations sources_stations_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.sources_stations
    ADD CONSTRAINT sources_stations_pkey PRIMARY KEY ("NetworkCode", "StationCode", try_order);
 P   ALTER TABLE ONLY public.sources_stations DROP CONSTRAINT sources_stations_pkey;
       public            gnss_data_osu    false    236    236    236                       2606    522527    stacks stacks_pkey 
   CONSTRAINT        ALTER TABLE ONLY public.stacks
    ADD CONSTRAINT stacks_pkey PRIMARY KEY ("NetworkCode", "StationCode", "Year", "DOY", name);
 <   ALTER TABLE ONLY public.stacks DROP CONSTRAINT stacks_pkey;
       public            gnss_data_osu    false    228    228    228    228    228                       2606    522529    stationalias stationalias_pkey 
   CONSTRAINT     v   ALTER TABLE ONLY public.stationalias
    ADD CONSTRAINT stationalias_pkey PRIMARY KEY ("NetworkCode", "StationCode");
 H   ALTER TABLE ONLY public.stationalias DROP CONSTRAINT stationalias_pkey;
       public            gnss_data_osu    false    229    229                       2606    522531    stationalias stationalias_uniq 
   CONSTRAINT     c   ALTER TABLE ONLY public.stationalias
    ADD CONSTRAINT stationalias_uniq UNIQUE ("StationAlias");
 H   ALTER TABLE ONLY public.stationalias DROP CONSTRAINT stationalias_uniq;
       public            gnss_data_osu    false    229            	           2606    522533 4   stationinfo stationinfo_NetworkCode_StationCode_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.stationinfo
    ADD CONSTRAINT "stationinfo_NetworkCode_StationCode_pkey" PRIMARY KEY ("NetworkCode", "StationCode", "DateStart");
 `   ALTER TABLE ONLY public.stationinfo DROP CONSTRAINT "stationinfo_NetworkCode_StationCode_pkey";
       public            gnss_data_osu    false    230    230    230                       2606    522535 .   stations stations_NetworkCode_StationCode_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.stations
    ADD CONSTRAINT "stations_NetworkCode_StationCode_pkey" PRIMARY KEY ("NetworkCode", "StationCode");
 Z   ALTER TABLE ONLY public.stations DROP CONSTRAINT "stations_NetworkCode_StationCode_pkey";
       public            gnss_data_osu    false    231    231            �           1259    522536    Filename    INDEX     N   CREATE INDEX "Filename" ON public.rinex USING btree ("Filename" varchar_ops);
    DROP INDEX public."Filename";
       public            gnss_data_osu    false    224            �           1259    522537    apr_coords_date_idx    INDEX     q   CREATE INDEX apr_coords_date_idx ON public.apr_coords USING btree ("NetworkCode", "StationCode", "Year", "DOY");
 '   DROP INDEX public.apr_coords_date_idx;
       public            gnss_data_osu    false    201    201    201    201            �           1259    522538    aws_sync_idx    INDEX     x   CREATE INDEX aws_sync_idx ON public.aws_sync USING btree ("NetworkCode", "StationCode", "StationAlias", "Year", "DOY");
     DROP INDEX public.aws_sync_idx;
       public            gnss_data_osu    false    202    202    202    202    202            �           1259    522539    etm_params_idx    INDEX     k   CREATE INDEX etm_params_idx ON public.etm_params USING btree ("NetworkCode", "StationCode", soln, object);
 "   DROP INDEX public.etm_params_idx;
       public            gnss_data_osu    false    205    205    205    205            �           1259    522540    events_index    INDEX     f   CREATE INDEX events_index ON public.events USING btree ("NetworkCode", "StationCode", "Year", "DOY");
     DROP INDEX public.events_index;
       public            gnss_data_osu    false    209    209    209    209            �           1259    522541    gamit_ztd_idx    INDEX     W   CREATE INDEX gamit_ztd_idx ON public.gamit_ztd USING btree ("Project", "Year", "DOY");
 !   DROP INDEX public.gamit_ztd_idx;
       public            gnss_data_osu    false    217    217    217            �           1259    522542    network_station    INDEX     q   CREATE INDEX network_station ON public.rinex USING btree ("NetworkCode" varchar_ops, "StationCode" varchar_ops);
 #   DROP INDEX public.network_station;
       public            gnss_data_osu    false    224    224            �           1259    522543    ppp_soln_idx    INDEX     �   CREATE INDEX ppp_soln_idx ON public.ppp_soln USING btree ("NetworkCode" COLLATE "C" varchar_ops, "StationCode" COLLATE "C" varchar_ops);
     DROP INDEX public.ppp_soln_idx;
       public            gnss_data_osu    false    221    221            �           1259    522544    ppp_soln_order    INDEX     j   CREATE INDEX ppp_soln_order ON public.ppp_soln USING btree ("NetworkCode", "StationCode", "Year", "DOY");
 "   DROP INDEX public.ppp_soln_order;
       public            gnss_data_osu    false    221    221    221    221            �           1259    522545    rinex_obs_comp_idx    INDEX     �   CREATE INDEX rinex_obs_comp_idx ON public.rinex USING btree ("NetworkCode", "StationCode", "ObservationYear", "ObservationDOY", "Completion");
 &   DROP INDEX public.rinex_obs_comp_idx;
       public            gnss_data_osu    false    224    224    224    224    224            �           1259    522546    rinex_obs_idx    INDEX     |   CREATE INDEX rinex_obs_idx ON public.rinex USING btree ("NetworkCode", "StationCode", "ObservationYear", "ObservationDOY");
 !   DROP INDEX public.rinex_obs_idx;
       public            gnss_data_osu    false    224    224    224    224                       1259    522547 
   stacks_idx    INDEX     F   CREATE INDEX stacks_idx ON public.stacks USING btree ("Year", "DOY");
    DROP INDEX public.stacks_idx;
       public            gnss_data_osu    false    228    228            
           1259    522548 $   stations_NetworkCode_StationCode_idx    INDEX     z   CREATE UNIQUE INDEX "stations_NetworkCode_StationCode_idx" ON public.stations USING btree ("NetworkCode", "StationCode");
 :   DROP INDEX public."stations_NetworkCode_StationCode_idx";
       public            gnss_data_osu    false    231    231            -           2620    522549    rinex update_stations    TRIGGER     z   CREATE TRIGGER update_stations AFTER INSERT ON public.rinex FOR EACH ROW EXECUTE FUNCTION public.update_timespan_trigg();
 .   DROP TRIGGER update_stations ON public.rinex;
       public          gnss_data_osu    false    224    243            .           2620    522550     stationalias verify_stationalias    TRIGGER     �   CREATE TRIGGER verify_stationalias BEFORE INSERT OR UPDATE ON public.stationalias FOR EACH ROW EXECUTE FUNCTION public.stationalias_check();
 9   DROP TRIGGER verify_stationalias ON public.stationalias;
       public          gnss_data_osu    false    229    241            '           2606    522551    stations NetworkCode    FK CONSTRAINT     �   ALTER TABLE ONLY public.stations
    ADD CONSTRAINT "NetworkCode" FOREIGN KEY ("NetworkCode") REFERENCES public.networks("NetworkCode") MATCH FULL ON UPDATE CASCADE ON DELETE RESTRICT;
 @   ALTER TABLE ONLY public.stations DROP CONSTRAINT "NetworkCode";
       public          gnss_data_osu    false    231    220    3054                       2606    522556    gamit_htc antenna_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.gamit_htc
    ADD CONSTRAINT antenna_fk FOREIGN KEY ("AntennaCode") REFERENCES public.antennas("AntennaCode") ON UPDATE CASCADE ON DELETE CASCADE;
 >   ALTER TABLE ONLY public.gamit_htc DROP CONSTRAINT antenna_fk;
       public          gnss_data_osu    false    3019    212    200                       2606    522561 &   apr_coords apr_coords_NetworkCode_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.apr_coords
    ADD CONSTRAINT "apr_coords_NetworkCode_fkey" FOREIGN KEY ("NetworkCode", "StationCode") REFERENCES public.stations("NetworkCode", "StationCode");
 R   ALTER TABLE ONLY public.apr_coords DROP CONSTRAINT "apr_coords_NetworkCode_fkey";
       public          gnss_data_osu    false    3084    231    201    201    231            (           2606    556356 (   data_source data_source_NetworkCode_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.data_source
    ADD CONSTRAINT "data_source_NetworkCode_fkey" FOREIGN KEY ("NetworkCode", "StationCode") REFERENCES public.stations("NetworkCode", "StationCode") ON UPDATE CASCADE ON DELETE RESTRICT;
 T   ALTER TABLE ONLY public.data_source DROP CONSTRAINT "data_source_NetworkCode_fkey";
       public          gnss_data_osu    false    231    3084    232    232    231                       2606    522566    etms etms_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.etms
    ADD CONSTRAINT etms_fk FOREIGN KEY ("NetworkCode", "StationCode") REFERENCES public.stations("NetworkCode", "StationCode") ON UPDATE CASCADE ON DELETE RESTRICT;
 6   ALTER TABLE ONLY public.etms DROP CONSTRAINT etms_fk;
       public          gnss_data_osu    false    3084    231    207    207    231                       2606    522571 &   gamit_soln gamit_soln_NetworkCode_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.gamit_soln
    ADD CONSTRAINT "gamit_soln_NetworkCode_fkey" FOREIGN KEY ("NetworkCode", "StationCode") REFERENCES public.stations("NetworkCode", "StationCode") ON UPDATE CASCADE ON DELETE RESTRICT;
 R   ALTER TABLE ONLY public.gamit_soln DROP CONSTRAINT "gamit_soln_NetworkCode_fkey";
       public          gnss_data_osu    false    3084    231    231    213    213                       2606    522576 0   gamit_soln_excl gamit_soln_excl_NetworkCode_fkey    FK CONSTRAINT     '  ALTER TABLE ONLY public.gamit_soln_excl
    ADD CONSTRAINT "gamit_soln_excl_NetworkCode_fkey" FOREIGN KEY ("NetworkCode", "StationCode", "Project", "Year", "DOY") REFERENCES public.gamit_soln("NetworkCode", "StationCode", "Project", "Year", "DOY") ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;
 \   ALTER TABLE ONLY public.gamit_soln_excl DROP CONSTRAINT "gamit_soln_excl_NetworkCode_fkey";
       public          gnss_data_osu    false    213    213    213    214    214    214    214    3039    213    214    213                       2606    522581 $   gamit_ztd gamit_ztd_NetworkCode_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.gamit_ztd
    ADD CONSTRAINT "gamit_ztd_NetworkCode_fkey" FOREIGN KEY ("NetworkCode", "StationCode") REFERENCES public.stations("NetworkCode", "StationCode");
 P   ALTER TABLE ONLY public.gamit_ztd DROP CONSTRAINT "gamit_ztd_NetworkCode_fkey";
       public          gnss_data_osu    false    217    231    231    3084    217                       2606    522586    locks locks_NetworkCode_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.locks
    ADD CONSTRAINT "locks_NetworkCode_fkey" FOREIGN KEY ("NetworkCode", "StationCode") REFERENCES public.stations("NetworkCode", "StationCode") ON UPDATE CASCADE ON DELETE CASCADE;
 H   ALTER TABLE ONLY public.locks DROP CONSTRAINT "locks_NetworkCode_fkey";
       public          gnss_data_osu    false    3084    219    231    231    219                       2606    522591 .   ppp_soln ppp_soln_NetworkName_StationCode_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.ppp_soln
    ADD CONSTRAINT "ppp_soln_NetworkName_StationCode_fkey" FOREIGN KEY ("NetworkCode", "StationCode") REFERENCES public.stations("NetworkCode", "StationCode") ON UPDATE CASCADE ON DELETE RESTRICT;
 Z   ALTER TABLE ONLY public.ppp_soln DROP CONSTRAINT "ppp_soln_NetworkName_StationCode_fkey";
       public          gnss_data_osu    false    231    231    221    3084    221                       2606    522596 ,   ppp_soln_excl ppp_soln_excl_NetworkCode_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.ppp_soln_excl
    ADD CONSTRAINT "ppp_soln_excl_NetworkCode_fkey" FOREIGN KEY ("NetworkCode", "StationCode") REFERENCES public.stations("NetworkCode", "StationCode") ON UPDATE CASCADE ON DELETE RESTRICT;
 X   ALTER TABLE ONLY public.ppp_soln_excl DROP CONSTRAINT "ppp_soln_excl_NetworkCode_fkey";
       public          gnss_data_osu    false    3084    231    231    222    222                       2606    522601    rinex rinex_NetworkCode_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.rinex
    ADD CONSTRAINT "rinex_NetworkCode_fkey" FOREIGN KEY ("NetworkCode", "StationCode") REFERENCES public.stations("NetworkCode", "StationCode") ON UPDATE CASCADE ON DELETE RESTRICT;
 H   ALTER TABLE ONLY public.rinex DROP CONSTRAINT "rinex_NetworkCode_fkey";
       public          gnss_data_osu    false    3084    231    231    224    224                        2606    522606 ,   rinex_tank_struct rinex_tank_struct_key_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.rinex_tank_struct
    ADD CONSTRAINT rinex_tank_struct_key_fkey FOREIGN KEY ("KeyCode") REFERENCES public.keys("KeyCode");
 V   ALTER TABLE ONLY public.rinex_tank_struct DROP CONSTRAINT rinex_tank_struct_key_fkey;
       public          gnss_data_osu    false    227    3050    218            )           2606    556381 +   sources_servers sources_servers_format_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.sources_servers
    ADD CONSTRAINT sources_servers_format_fkey FOREIGN KEY (format) REFERENCES public.sources_formats(format);
 U   ALTER TABLE ONLY public.sources_servers DROP CONSTRAINT sources_servers_format_fkey;
       public          gnss_data_osu    false    3088    233    235            *           2606    556405 >   sources_stations sources_stations_NetworkCode_StationCode_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.sources_stations
    ADD CONSTRAINT "sources_stations_NetworkCode_StationCode_fkey" FOREIGN KEY ("NetworkCode", "StationCode") REFERENCES public.stations("NetworkCode", "StationCode");
 j   ALTER TABLE ONLY public.sources_stations DROP CONSTRAINT "sources_stations_NetworkCode_StationCode_fkey";
       public          gnss_data_osu    false    3084    236    236    231    231            +           2606    556400 -   sources_stations sources_stations_format_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.sources_stations
    ADD CONSTRAINT sources_stations_format_fkey FOREIGN KEY (format) REFERENCES public.sources_formats(format);
 W   ALTER TABLE ONLY public.sources_stations DROP CONSTRAINT sources_stations_format_fkey;
       public          gnss_data_osu    false    236    3088    233            ,           2606    556395 0   sources_stations sources_stations_server_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.sources_stations
    ADD CONSTRAINT sources_stations_server_id_fkey FOREIGN KEY (server_id) REFERENCES public.sources_servers(server_id);
 Z   ALTER TABLE ONLY public.sources_stations DROP CONSTRAINT sources_stations_server_id_fkey;
       public          gnss_data_osu    false    235    3090    236            !           2606    522611    stacks stacks_NetworkCode_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.stacks
    ADD CONSTRAINT "stacks_NetworkCode_fkey" FOREIGN KEY ("NetworkCode", "StationCode") REFERENCES public.stations("NetworkCode", "StationCode") ON UPDATE CASCADE ON DELETE RESTRICT;
 J   ALTER TABLE ONLY public.stacks DROP CONSTRAINT "stacks_NetworkCode_fkey";
       public          gnss_data_osu    false    228    231    3084    231    228            "           2606    522616    stacks stacks_gamit_soln_fkey    FK CONSTRAINT       ALTER TABLE ONLY public.stacks
    ADD CONSTRAINT stacks_gamit_soln_fkey FOREIGN KEY ("Year", "DOY", "StationCode", "Project", "NetworkCode") REFERENCES public.gamit_soln("Year", "DOY", "StationCode", "Project", "NetworkCode") ON UPDATE CASCADE ON DELETE CASCADE;
 G   ALTER TABLE ONLY public.stacks DROP CONSTRAINT stacks_gamit_soln_fkey;
       public          gnss_data_osu    false    213    228    228    228    228    228    213    213    213    213    3039            #           2606    522621    stationalias stationalias_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.stationalias
    ADD CONSTRAINT stationalias_fk FOREIGN KEY ("NetworkCode", "StationCode") REFERENCES public.stations("NetworkCode", "StationCode") ON UPDATE CASCADE ON DELETE RESTRICT;
 F   ALTER TABLE ONLY public.stationalias DROP CONSTRAINT stationalias_fk;
       public          gnss_data_osu    false    231    231    229    229    3084            $           2606    522626 (   stationinfo stationinfo_AntennaCode_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.stationinfo
    ADD CONSTRAINT "stationinfo_AntennaCode_fkey" FOREIGN KEY ("AntennaCode") REFERENCES public.antennas("AntennaCode") ON UPDATE CASCADE ON DELETE RESTRICT;
 T   ALTER TABLE ONLY public.stationinfo DROP CONSTRAINT "stationinfo_AntennaCode_fkey";
       public          gnss_data_osu    false    230    3019    200            %           2606    522631 4   stationinfo stationinfo_NetworkCode_StationCode_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.stationinfo
    ADD CONSTRAINT "stationinfo_NetworkCode_StationCode_fkey" FOREIGN KEY ("NetworkCode", "StationCode") REFERENCES public.stations("NetworkCode", "StationCode") ON UPDATE CASCADE ON DELETE RESTRICT;
 `   ALTER TABLE ONLY public.stationinfo DROP CONSTRAINT "stationinfo_NetworkCode_StationCode_fkey";
       public          gnss_data_osu    false    3084    230    231    231    230            &           2606    522636 )   stationinfo stationinfo_ReceiverCode_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.stationinfo
    ADD CONSTRAINT "stationinfo_ReceiverCode_fkey" FOREIGN KEY ("ReceiverCode") REFERENCES public.receivers("ReceiverCode") ON UPDATE CASCADE ON DELETE RESTRICT;
 U   ALTER TABLE ONLY public.stationinfo DROP CONSTRAINT "stationinfo_ReceiverCode_fkey";
       public          gnss_data_osu    false    3062    223    230                       2606    522641    etm_params stations_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.etm_params
    ADD CONSTRAINT stations_fk FOREIGN KEY ("NetworkCode", "StationCode") REFERENCES public.stations("NetworkCode", "StationCode");
 @   ALTER TABLE ONLY public.etm_params DROP CONSTRAINT stations_fk;
       public          gnss_data_osu    false    205    231    205    231    3084           