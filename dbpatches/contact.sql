--
-- Patch by Javier Talens. Fix missed column when try to migrate from D6 to D7
--
--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;
ALTER USER javier SET search_path TO public;

--
-- Name: contact; Type: TABLE; Schema: public; Owner: javier; Tablespace:
--

CREATE TABLE contact (
   cid integer NOT NULL,
   category character varying(255) DEFAULT ''::character varying NOT NULL,
   recipients text NOT NULL,
   reply text NOT NULL,
   weight integer DEFAULT 0 NOT NULL,
   selected smallint DEFAULT 0 NOT NULL,
   CONSTRAINT contact_cid_check CHECK ((cid >= 0))
);

ALTER TABLE contact ADD weight integer DEFAULT 0 NOT NULL;

ALTER TABLE contact ADD category character varying(255) DEFAULT ''::character varying NOT NULL;

ALTER TABLE public.contact OWNER TO javier;

--
-- Name: TABLE contact; Type: COMMENT; Schema: public; Owner: javier
--

COMMENT ON TABLE contact IS 'Contact form category settings.';


--
-- Name: COLUMN contact.cid; Type: COMMENT; Schema: public; Owner: javier
--

COMMENT ON COLUMN contact.cid IS 'Primary Key: Unique category ID.';


--
-- Name: COLUMN contact.category; Type: COMMENT; Schema: public; Owner: javier
--

COMMENT ON COLUMN contact.category IS 'Category name.';


--
-- Name: COLUMN contact.recipients; Type: COMMENT; Schema: public; Owner: javier
--

COMMENT ON COLUMN contact.recipients IS 'Comma-separated list of recipient e-mail addresses.';


--
-- Name: COLUMN contact.reply; Type: COMMENT; Schema: public; Owner: javier
--

COMMENT ON COLUMN contact.reply IS 'Text of the auto-reply message.';


--
-- Name: COLUMN contact.weight; Type: COMMENT; Schema: public; Owner: javier
--

COMMENT ON COLUMN contact.weight IS 'The category''s weight.';


--
-- Name: COLUMN contact.selected; Type: COMMENT; Schema: public; Owner: javier
--

COMMENT ON COLUMN contact.selected IS 'Flag to indicate whether or not category is selected by default. (1 = Yes, 0 = No)';


--
-- Name: contact_cid_seq; Type: SEQUENCE; Schema: public; Owner: javier
--

CREATE SEQUENCE contact_cid_seq
   START WITH 1
   INCREMENT BY 1
   NO MAXVALUE
   NO MINVALUE
   CACHE 1;


ALTER TABLE public.contact_cid_seq OWNER TO javier;

--
-- Name: contact_cid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: javier
--

ALTER SEQUENCE contact_cid_seq OWNED BY contact.cid;


--
-- Name: contact_cid_seq; Type: SEQUENCE SET; Schema: public; Owner: javier
--

SELECT pg_catalog.setval('contact_cid_seq', 1, true);


--
-- Name: cid; Type: DEFAULT; Schema: public; Owner: javier
--

ALTER TABLE ONLY contact ALTER COLUMN cid SET DEFAULT nextval('contact_cid_seq'::regclass);


--
-- Data for Name: contact; Type: TABLE DATA; Schema: public; Owner: javier
--

COPY contact (cid, category, recipients, reply, weight, selected) FROM stdin;
1	Website feedback	javier.segui@uib.no		0	1
\.


--
-- Name: contact_category_key; Type: CONSTRAINT; Schema: public; Owner: javier; Tablespace:
--

ALTER TABLE ONLY contact
   ADD CONSTRAINT contact_category_key UNIQUE (category);


--
-- Name: contact_pkey; Type: CONSTRAINT; Schema: public; Owner: javier; Tablespace:
--

ALTER TABLE ONLY contact
   ADD CONSTRAINT contact_pkey PRIMARY KEY (cid);


--
-- Name: contact_list_idx; Type: INDEX; Schema: public; Owner: javier; Tablespace:
--

CREATE INDEX contact_list_idx ON contact USING btree (weight, category);


--
-- PostgreSQL database dump complete
--

