# Installation

### Prerequirements

1. Docker installed

### DB Setup

Skip this part if you are using an existing db

1. bash command as postgres user: createuser gnss_data_osu;
2. bash command as postgres user: createdb gnss;
3. psql command as postgres user at postgres db: alter user gnss_data_osu with password 'password';
4. bash command as postgres user: psql -d gnss -f DUMP_FILE_PATH > LOG_FILE_PATH 2>&1 &
5. psql command as postgres user at postgres db: alter database gnss owner to gnss_data_osu;
6. psql command as postgres user at postgres db: GRANT ALL PRIVILEGES ON DATABASE gnss TO gnss_data_osu;
7. set postgresql.conf file properly
8. set pg_hba.conf file properly

### Procedure

1. Define a conf file named "gnss_data.cfg" following the example under 'backend/' following 'backend/conf_example.txt'
2. From the root directory:

   ```
   cd backend
   sudo docker build -t gnss-backend .
   sudo docker run -d --network host --restart always --mount type=bind,src="$(pwd)",target=/code gnss-backend
   ```

# Tests

There are some test created. Before running them, you need to manually create an empty database with the same schema as the one used in production.

This database should be named 'test\_{PRODUCTION_DB_NAME}' and should be accessible by the user specified in the config file.

You should use the script 'db/modify_test_db.py' to remove some tables that may generate conflict. DONT forget to
set .env under 'db' folder file with test db credentials.

To run the tests, under root directory

    ```
    cd backend/backend_django_project/
    python manage.py test --keepdb
    ```
