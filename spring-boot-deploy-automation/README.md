## Directory structure

```
spring-boot-deploy-automation
|-- artefacts
|   |-- repo
|-- repositories
|   |-- repo
|-- resources
|   |-- repo
`-- deploy.sh
```


## Command examples

```
             ┌─ action
             │
./deploy.sh init git@gitlab.local:username/project.git 
                                        │
                     project clone url ─┘
```
```
               ┌─ action
               │         ┌─ repository name from repositories/
               │         │
./deploy.sh build spring-boot
```
```
               ┌─ action
               │         ┌─ repository name from repositories/
               │         │
               │         │
./deploy.sh database spring-boot localhost postgres postgres
                                     │        │        │
                      database host ─┘        │        │
                               database name ─┘        │
                                    database username ─┘
```
```
               ┌─ action
               │         ┌─ repository name from repositories/
               │         │      ┌─ application port
               │         │      │
./deploy.sh deploy spring-boot 8080 localhost postgres postgres
                                        │        │        │
                         database host ─┘        │        │
                                  database name ─┘        │
                                       database username ─┘
``` 


## Sample output

```
silverdrop@nexus:~/deploy$ ./deploy.sh deploy spring-boot 8080 localhost postgres postgres
[!] Navigate to spring-boot
/home/silverdrop/deploy/repositories/spring-boot
[✔] Navigate to spring-boot

[!] Directory is git repository
[✔] Directory is git repository

[!] Pull changes from gitlab
From gitlab.local:vrachieru/spring-boot
 * branch            master     -> FETCH_HEAD
Already up-to-date.
[✔] Pull changes from gitlab

[!] Build the project
[INFO] Scanning for projects...
[INFO]                                                                         
[INFO] ------------------------------------------------------------------------
[INFO] Building spring-boot 0.0.1-SNAPSHOT
[INFO] ------------------------------------------------------------------------
[INFO] 
[INFO] --- maven-clean-plugin:2.5:clean (default-clean) @ spring-boot ---
[INFO] Deleting /home/silverdrop/deploy/repositories/spring-boot/target
[INFO] 
[INFO] --- maven-resources-plugin:2.6:resources (default-resources) @ spring-boot ---
[INFO] Using 'UTF-8' encoding to copy filtered resources.
[INFO] Copying 1 resource
[INFO] Copying 61 resources
[INFO] 
[INFO] --- maven-compiler-plugin:3.1:compile (default-compile) @ spring-boot ---
[INFO] Changes detected - recompiling the module!
[INFO] Compiling 25 source files to /home/silverdrop/deploy/repositories/spring-boot/target/classes
[INFO] 
[INFO] --- maven-resources-plugin:2.6:testResources (default-testResources) @ spring-boot ---
[INFO] Not copying test resources
[INFO] 
[INFO] --- maven-compiler-plugin:3.1:testCompile (default-testCompile) @ spring-boot ---
[INFO] Not compiling test sources
[INFO] 
[INFO] --- maven-surefire-plugin:2.17:test (default-test) @ spring-boot ---
[INFO] Tests are skipped.
[INFO] 
[INFO] --- maven-jar-plugin:2.5:jar (default-jar) @ spring-boot ---
[INFO] Building jar: /home/silverdrop/deploy/repositories/spring-boot/target/spring-boot-0.0.1-SNAPSHOT.jar
[INFO] 
[INFO] --- spring-boot-maven-plugin:1.2.5.RELEASE:repackage (default) @ spring-boot ---
[INFO] 
[INFO] --- maven-install-plugin:2.5.2:install (default-install) @ spring-boot ---
[INFO] Installing /home/silverdrop/deploy/repositories/spring-boot/target/spring-boot-0.0.1-SNAPSHOT.jar to /home/silverdrop/.m2/repository/org/test/spring-boot/0.0.1-SNAPSHOT/spring-boot-0.0.1-SNAPSHOT.jar
[INFO] Installing /home/silverdrop/deploy/repositories/spring-boot/pom.xml to /home/silverdrop/.m2/repository/org/test/spring-boot/0.0.1-SNAPSHOT/spring-boot-0.0.1-SNAPSHOT.pom
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time: 13.998s
[INFO] Finished at: Sat Oct 10 13:11:42 EEST 2015
[INFO] Final Memory: 25M/186M
[INFO] ------------------------------------------------------------------------
[✔] Build the project

[!] Identify artefact in target
/home/silverdrop/deploy/repositories/spring-boot/target/spring-boot-0.0.1-SNAPSHOT.jar
[✔] Identify artefact in target

[!] Substitute resources within artefact
adding: application.properties(in = 0) (out= 0)(stored 0%)
[✔] Substitute resources within artefact

[!] Kill all processes running on port 8080
[✔] Kill all processes running on port 8080

[!] Backup previously deployed artefacts
‘../../artefacts/spring-boot/spring-boot-0.0.1-SNAPSHOT-20151010131143.jar’ -> ‘../../artefacts/spring-boot/spring-boot-0.0.1-SNAPSHOT-20151010131143.jar-backup’
[✔] Backup previously deployed artefacts

[!] Copy the artefact with updated resources
‘/home/silverdrop/deploy/repositories/spring-boot/target/spring-boot-0.0.1-SNAPSHOT.jar’ -> ‘../../artefacts/spring-boot/spring-boot-0.0.1-SNAPSHOT-20151010131538.jar’
[✔] Copy the artefact with updated resources

[!] Execute database scripts
[?] Execute src/main/resources/sql/create.sql (y/n): y
Password for user postgres: 
DROP TABLE IF EXISTS users;
DROP TABLE
CREATE TABLE IF NOT EXISTS users (
  id SERIAL UNIQUE NOT NULL,
  user_name VARCHAR(100),
  user_email VARCHAR(100) UNIQUE,
  user_password VARCHAR(70),
  user_first_name VARCHAR(100),
  user_last_name VARCHAR(100),
  user_role role,
  PRIMARY KEY(id)
);
CREATE TABLE
[✔] Execute src/main/resources/sql/create.sql

[?] Execute src/main/resources/sql/insert.sql (y/n): n
[✔] Execute database scripts

[!] Start the application
nohup: appending output to ‘nohup.out’
[✔] Start the application
```