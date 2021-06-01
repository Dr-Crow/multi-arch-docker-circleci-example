FROM python:3.9-slim

ARG USER=demo
ARG GROUP=demo
ARG UID=1000
ARG GID=1000
ARG HTTP_PORT=80

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

# Install required packages for the demo and remove the text file
RUN pip install --no-cache-dir -r requirements.txt \
    && rm -f requirements.txt

# Switch to non-root user
USER demo

# Set Python3 as entrypoint
# Using -u for unbuffered ouput
ENTRYPOINT ["python3", "-u"]

# Run the Flask Demo
CMD ["flask_run.py"]