.PHONY: run test docs ci clean

run:
	dbt run

test:
	dbt test

docs:
	dbt docs generate && dbt docs serve

ci:
	dbt run && dbt test

clean:
	dbt clean
