FROM python:3.9-slim

ARG USER=demo
ARG GROUP=demo
ARG UID=1000
ARG GID=1000
ARG HTTP_PORT=8080

# Set enviroment variable for Flask
ENV HTTP_PORT=${HTTP_PORT}

# Expose the server port
EXPOSE ${HTTP_PORT}

# Copy in requirements file for demp
COPY ./demo /demo

# Add a group and user to not use root
# Then set permissions to the demo files
RUN addgroup --gid ${GID} ${GROUP} \
  && adduser --disabled-password --no-create-home --home "/demo" --uid ${UID} --ingroup ${GROUP} ${USER} \
  && chown -R ${UID}:${GID} /demo

# Set Working Directory
WORKDIR /demo

# Installs need packages to compile psycopg2 as there is no arm64 binary in PyPi
# Then removes build dependencies and requirements.txt
RUN BUILDDEPS='libpq-dev python3-dev gcc' \
    && apt-get update && apt-get upgrade -y \
    && apt-get --no-install-recommends install -y ${BUILDDEPS} \
    && pip install --no-cache-dir -r requirements.txt \
    && rm -f requirements.txt \
    && apt-get purge -y --auto-remove ${BUILDDEPS} \
    && rm -rf /var/lib/apt/lists/*

# Switch to non-root user
USER demo

# Set Python3 as entrypoint
# Using -u for unbuffered ouput
ENTRYPOINT ["python3", "-u"]

# Run the Flask Demo
CMD ["flask_run.py"]