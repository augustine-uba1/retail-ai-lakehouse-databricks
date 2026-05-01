CREATE SCHEMA IF NOT EXISTS IDENTIFIER({{catalog_name}} || '.bronze')
COMMENT 'Raw and lightly processed retail source data';

CREATE SCHEMA IF NOT EXISTS IDENTIFIER({{catalog_name}} || '.silver')
COMMENT 'Cleaned and conformed retail data';

CREATE SCHEMA IF NOT EXISTS IDENTIFIER({{catalog_name}} || '.gold')
COMMENT 'Business-ready analytics tables for Genie and reporting';

CREATE SCHEMA IF NOT EXISTS IDENTIFIER({{catalog_name}} || '.ai')
COMMENT 'AI-ready tables for document chunks, embeddings and Vector Search';

CREATE SCHEMA IF NOT EXISTS IDENTIFIER({{catalog_name}} || '.audit')
COMMENT 'Pipeline audit, reconciliation and data quality metrics';