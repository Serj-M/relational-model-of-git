# Mining Software Repositories based on a relational model

This repository contains materials for **Mining Software Repositories (MSR)** aimed at identifying code hotspots from a relational Git data model. The model provides end-to-end traceability **File → Commit → Pull Request → Issue**.

Included are example SQL queries and DDL for the database schema, anonymized CSV outputs of these queries, Python code to compute the intersection of three hotspot criteria (change frequency, contributor count, bugfix-related changes) and to rank files by average rank.
