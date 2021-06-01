# Multi-Arch Docker CircleCI Example

With the release of CircleCI's Arm executor, we can now build on multiple architectures via CircleCI's Cloud offering. 
Building on architecture offers better performance/speed and the assurance that your application will indeed work on your platform.

While some examples show using Docker Buildx with QEMU, this can lead to issues with low level languages looking like
they work, but in reality they fail when deployed on your platform.  

For this example we will build a Python application, build Docker images for each architecture(`arm64` and `amd64`), 
and construct a manifest to tie the Docker images together into a single tag. 

## CI Setup

For this example we will be using CircleCI infrastructure to build, test and push Docker images. The two main executors
we will be using is the machine executor for both `amd64` and `arm64`. 

We want to setup CircleCI to accomplish the following:

- Trigger on every commit to `main` and every PR on this repo
- Build the Flask Demo container
- Test the container to make sure it is functioning
- If tests past, tag the images and push the architecture specific images
- Create Docker manifests to allow users to pull down the image without caring about architecture


That should cover the CI part of this example. To fully flush out a "true" demo we would also want to deploy our Docker
images to a hosting provider like [Amazon's ECS](https://docs.docker.com/cloud/ecs-integration/) or some sort of Kubernetes
offering like [Google Kubernetes Engine (GKE)](https://cloud.google.com/kubernetes-engine). Deploying tested Docker images
would cover the CD part of this example. For now, we will not be covering that as running cloud services over a period of
time will add up quickly.


## Deployment Documentation

### Python/Flask Application

Project structure:

```
.
├── .ci                         - Docker Build Tools
├── demo
|    ├── app/                   - Python Application
|    ├── requirements.txt
|    └── flask_run.py
|    └── config.py
├── depolyment                  - Deployment Files for Full Stack Application (Postgres + Flask App) 
|    |── docker-compose.yml
|    |── config/                - Configuration files for Full Stack Deployment (SQL files)
|    |── env/                   - Enviroment File for Full Stack Deployment (DB Creds and Flask Creds)
├── Dockerfile                  - Flask Application Dockerfile

```

[_docker-compose.yaml_](deployment/docker-compose.yaml)

```yaml
version: "3.6"
services:
  flask:
    build:
        dockerfile: Dockerfile
        context: ../
    ports:
      - "8080:80"
    restart: unless-stopped
    env_file:
      - env/demo.env
    depends_on:
      - db
  db:
    image: postgres:13-alpine
    restart: always
    env_file:
      - env/demo.env
    volumes:
      - ./config/user_and_role.sql:/docker-entrypoint-initdb.d/user_and_role.sql
      #- /tmp/demo:/var/lib/postgresql/data -- If you want to save the database files for testing
```

[_demo.env_](deployment/env/demo.env)

```ini
# Application
FLASK_CONFIG=development
DATABASE_IP=db
DATABASE_PORT=5432
DATABASE_USERNAME=demo_user
DATABASE_PASSWORD=demo_password
DATABASE_NAME=demo_db
SECRET_KEY=multi-arch


# Database
POSTGRES_DB=demo_db
POSTGRES_USER=demo_user
POSTGRES_PASSWORD=demo_password
```

## Deploy with docker-compose

```
$ cd depolyment/
$ docker-compose up -d
Docker Compose is now in the Docker CLI, try `docker compose up`

Building flask....


Creating deployment_db_1 ... done  
Creating deployment_flask_1 ... done   

```

## Expected result

Listing containers must show two container running and the port mapping as below:

```
$ docker ps
CONTAINER ID   IMAGE                COMMAND                  CREATED              STATUS              PORTS                                   NAMES
8061b039362f   deployment_flask     "python3 -u flask_ru…"   About a minute ago   Up About a minute   0.0.0.0:8080->80/tcp, :::8080->80/tcp   deployment_flask_1
6b1c5697ea75   postgres:13-alpine   "docker-entrypoint.s…"   About a minute ago   Up About a minute   5432/tcp                                deployment_db_1
```

After the application starts, navigate to `http://localhost:8080` in your web browser.

Stop and remove the containers

```
$ docker-compose down
```