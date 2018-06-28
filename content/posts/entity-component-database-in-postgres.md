---
title: "Entity Component Database in Postgres"
date: 2017-10-20T23:25:40+02:00
draft: true
---

Taking a fresh look at how to model a document database in Postgres. Combining some ideas from
Game development, apply them to the structure of web content and implement them on Postgres.

What was a simple experiment at first, is now a document database service more than 130 thousand
articles in production. No schema, only documents, down to a single paragraph.

<!--more-->

## Tables

All documents are stored in the `documents` table. For a start, this is sufficient. With the recent
improvements on table partitioning, these could be clearly optimized per role.

Having no schema on the documents, allows development to iterate quickly. With the project maturing,
and tables split up by role, classical RDS schemes could be introduced where they are needed.

```sql
CREATE TABLE documents (
  id serial not null primary key,
  role varchar(255),
  data jsonb
);

CREATE INDEX documents_role_idx ON documents (role);
```

The next table is `document_relations`. This is where the **component** idea comes to live.

This database and table structure is intended to store **tree based, hierarchical** data.
If you think about it, you will find many areas where this is directly applicable. My use case was **web content**.

Given a simple web page with a heading, gallery, some paragraphs and a form.
You can imagine the following hierarchy of these **components**.

* root
  * heading
  * gallery
      * image
      * image
      * image
  * paragraph
  * paragraph
  * image
  * paragraph
  * form
      * paragraph
      * input
      * paragraph
      * button

In the following table, I want to represent the hierarchy between documents. And I found **int arrays**
to be very efficient to store and operate on a list of direct children.

Why an **int array**?

The reasoning behind that decision, is that **content must be reliably ordered**. Implementing a foreign reference
with ordering is actually quite hard using pure RDS-tables.

And Postgres has excellent support for integer arrays.

Adding to that, my case exhibited a read/write ratio of about 95/5. So the database is usally busy
with reading data than writing it.

Obviously, if one must add/change or remove a child from the tree, these operations must be done carefully.

Read more about write operations below.
Here is the schema to build a `document_relations` table.

```sql
CREATE TABLE document_relations (
  document_id integer references documents (id) ON DELETE restrict primary key,
  children integer[]
);
CREATE INDEX drel_idx ON document_relations USING GIN ("children");
```

## Querying

```sql
WITH RECURSIVE tree (id, role, parent_id, lvl, data, path) AS (
  (
    /*
      This query selects all the root documents.
      Use it to limit the number of root nodes to start a tree from.
    */
    SELECT
      d.id,       /* the id of the document */
      d.role,
      d.id,       /* the parent id, a root is its own parent */
      0,          /* the level (depth) of roots is 0 */
      d.data,
      ARRAY[d.id] /* the path starts with the root id */
    FROM documents d
    /*
      This where clause (and possible JOINS or LIMIT) is important.
      It limits the number of root nodes you are querying a tree for.
    */
    WHERE d.id = 4
  )
  UNION
  (
    /*
      This query is called recursively and thus can select from `tree` (the root documents and subsequent results).
      It must return the same columns as the starting query.
    */
    SELECT
      t.id,
      d.role,
      t.parent_id,
      t.lvl,
      d.data,
      t.path || t.id
    FROM (
      /*
        This query unnests (expands) the children array to rows, so we can JOIN them in the outer query.
        Here you usually do not want to change something with one exception a WHERE clause for tree depth.
      */
      SELECT
        unnest(dt.children) as id,
        dt.document_id as parent_id,
        tree.lvl + 1 as lvl,
        tree.path as path
      FROM document_tree dt, tree
      WHERE dt.document_id = tree.id
      /* Optionally you can limit the depth of any tree in your result
        e.g. limit all trees to a depth of 2.
        
        AND tree.lvl + 1 <= 2
      */
    ) t
    JOIN documents d ON d.id = t.id
    /* Guard against cyclic references */
    WHERE NOT(ARRAY[t.id] && t.path)
    /* Optionally you can limit the resulting child-nodes with further where clauses
      e.g. only return child-nodes with role 'article'
      
      AND d.role = 'article'
    */
  )
)
/*
  This returns the result set from the recursive common table expression.
  
  At this point you can also add more CTEs.
  
  In general it makes sense to put a LIMIT on the result set.
*/
SELECT * FROM tree
```

## Testing with deep hierarchical data

A good testing bed for large and deep tree structures is the ITIS database. It is available for Postgres, download here [https://www.itis.gov/downloads/].

When using the ITIS dataset, you can use the following queries to rebuild their dataset into the entity component databse:

```sql
INSERT INTO documents
SELECT
	DISTINCT ON (h.tsn)
	h.tsn as id,
	CASE
		WHEN h.parent_tsn = 0 THEN 'root'
		ELSE lower(coalesce(j.jurisdiction_value, 'no-jurisdiction'))
	END as role,
	jsonb_build_object(
		'name', l.completename,
		'geo', g.geographic_value,
		'children_count', h.childrencount
	) as data
from hierarchy h
LEFT JOIN geographic_div g ON h.tsn = g.tsn
LEFT JOIN longnames l ON h.tsn = l.tsn
LEFT JOIN jurisdiction j ON h.tsn = j.tsn
```

```
INSERT INTO document_relations
SELECT
	h.parent_tsn as document_id,
	array_agg(h.tsn) as children
from hierarchy h
where h.parent_tsn > 0
group by h.parent_tsn
```

