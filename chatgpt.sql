/*
Skills used include table creation, constraint assignment, data cleaning, basic SELECT statements, data filtering, GROUP BY statement's, CTE's, and window functions
*/

-- Creating tables and assigning constraints


CREATE TABLE public.full_data (
    user_name VARCHAR NOT NULL,
    text character VARCHAR,
    user_location VARCHAR,
    user_description VARCHAR,
    user_created timestamp without time zone,
    user_followers INT,
    user_friends INT,
    user_favourites INT,
    user_verified VARCHAR,
    date timestamp without time zone,
    hashtags VARCHAR,
    source VARCHAR,
    CONSTRAINT constraint_name CHECK (condition)
);

CREATE TABLE post_data AS (
  SELECT text, date, hashtags, source
  FROM full_data
);
CREATE TABLE user_data AS (
  SELECT user_name, user_location, user_description, user_created, user_followers, user_friends, date, hashtags, source
  FROM full_data
);

-- Most commonly occuring words (excluding stop words)

WITH tokenized_text_data AS (
  SELECT regexp_split_to_table(lower(text), '\s+') AS word
  FROM full_data
),
stop_words AS (
  SELECT *
  FROM unnest(string_to_array('a,an,and,are,as,at,be,by,for,from,has,he,in,is,it,its,of,on,that,the,to,was,were,will,with,you,and,this,i,can,what,my,how,but,have,not,we,just,your,like,me,if,about,asked,or,new,so,more,it''s,do,-', ',')) AS stop_word
)
SELECT word, COUNT(word) AS frequency
FROM tokenized_text_data
WHERE word NOT IN (SELECT stop_word FROM stop_words)
GROUP BY word
ORDER BY frequency DESC;

-- Removing emojis from the text column to allow for easier analysis

WITH cleaned_text_data AS (
  SELECT regexp_replace(text, '[^\x00-\x7F]+', '', 'g') AS cleaned_text
  FROM full_data
)
SELECT *
FROM cleaned_text_data;

-- Most popular locations

SELECT user_location, COUNT(user_name) AS location_count
FROM full_data
GROUP BY user_location
ORDER BY COUNT(user_name) DESC

-- Most popular posting devices

SELECT source, COUNT(*)
FROM full_data
GROUP BY source
ORDER BY count DESC

-- Hashtag count

SELECT hashtags, (LENGTH(hashtags) - LENGTH(REPLACE(hashtags, ',', '')) + 1) AS hashtag_count
FROM full_data
ORDER BY hashtag_count DESC NULLS LAST


-- Time-series analysis

SELECT date_trunc('day', date), count(*)
FROM full_data
GROUP  BY 1
ORDER BY date_trunc ASC

-- Most popular posting times

SELECT date_trunc('hour', date), count(*) as posts
FROM full_data
GROUP  BY 1
ORDER BY date_trunc ASC

SELECT date_trunc('hour', date), count(*) as posts
FROM full_data
GROUP  BY date_trunc
ORDER BY count(*) DESC

-- Most popular hashtags

SELECT unnest(string_to_array(REGEXP_REPLACE(hashtags,'[^\w,]+','','g'), ',')) as tags, count(1)
FROM full_data
GROUP BY tags
ORDER BY count(1) desc

-- OR

WITH unnested AS
(SELECT
TRIM(TRANSLATE(UNNEST(STRING_TO_ARRAY(hashtags, ',')),'#,[,]','')) AS hashtag
FROM full_data)
SELECT hashtag, COUNT(hashtag) 
FROM unnested
GROUP BY hashtag
ORDER BY COUNT(hashtag) DESC;

-- Window Function ROW_NUMBER to rank words (stop words excluded)

WITH tokenized_text_data AS (
  SELECT regexp_split_to_table(lower(text), '\s+') AS word
  FROM full_data
),
stop_words AS (
  SELECT *
  FROM unnest(string_to_array('a,an,and,are,as,at,be,by,for,from,has,he,in,is,it,its,of,on,that,the,to,was,were,will,with,you,and,this,i,can,what,my,how,but,have,not,we,just,your,like,me,if,about,asked,or,new,so,more,it''s,do,-', ',')) AS stop_word
),
frequency_table AS (
  SELECT word, COUNT(word) AS frequency
  FROM tokenized_text_data
  WHERE word NOT IN (SELECT stop_word FROM stop_words)
  GROUP BY word
)
SELECT word, frequency, ROW_NUMBER() OVER (ORDER BY frequency DESC) AS rank
FROM frequency_table
ORDER BY frequency DESC;
