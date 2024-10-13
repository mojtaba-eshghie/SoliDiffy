# Use an official Python image as the base image
FROM python:3.10.12-slim

# Install Java (OpenJDK 17) and necessary build tools
RUN apt-get update && \
    apt-get install -y openjdk-17-jdk curl unzip && \
    apt-get clean

# Set environment variables for Java
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH

# Install Gradle
RUN apt-get update && \
    apt-get install -y gradle && \
    apt-get clean

# Set the working directory to /app
WORKDIR /app

RUN apt-get update && apt-get install -y git build-essential && rm -rf /var/lib/apt/lists/*


# Clone the SoliDiffy repository
RUN apt-get install -y git
RUN git clone https://anonymous.4open.science/r/SoliDiffy-EF2A

# Change directory to SoliDiffy
WORKDIR /app/SoliDiffy

# Install Python dependencies
RUN pip install --upgrade pip
RUN pip install tree-sitter==0.20.4
RUN pip install gitpython==3.1.24
RUN pip install pyyaml==6.0.2


# Initialize and update git submodules
#RUN git submodule init --recursive && git submodule update --recursive
#RUN git submodule update --init --recursive



# Clean existing submodule directories if they exist
RUN rm -rf gumtree tree-sitter-parser


# Override submodule URLs to use HTTPS
RUN git config --file .gitmodules submodule.gumtree.url https://github.com/ViktorAryd/gumtree.git
RUN git config --file .gitmodules submodule.tree-sitter-parser.url https://github.com/ViktorAryd/tree-sitter-parser.git



# Initialize and update git submodules with the new URLs
RUN git submodule sync
RUN git submodule update --init


RUN git config --file tree-sitter-parser/.gitmodules submodule.tree-sitter-solidity.url https://github.com/JoranHonig/tree-sitter-solidity.git

RUN cd tree-sitter-parser 
RUN git submodule update --init
RUN cd ..



# Initialize and update submodules for tree-sitter-parser
WORKDIR /app/SoliDiffy/tree-sitter-parser
RUN git submodule init && git submodule update


RUN python /app/SoliDiffy/tree-sitter-parser/tree-sitter-parser.py /app/SoliDiffy/example/original.sol solidity


# Build Gumtree with Gradle
WORKDIR /app/SoliDiffy/gumtree
RUN ./gradlew build

# Unzip the Gumtree distribution and add it to the PATH
RUN unzip dist/build/distributions/gumtree-3.1.0-SNAPSHOT.zip -d /app/SoliDiffy/gumtree/dist/build/distributions/
ENV PATH="/app/SoliDiffy/gumtree/dist/build/distributions/gumtree-3.1.0-SNAPSHOT/bin:$PATH"

# Add tree-sitter-parser to PATH
ENV PATH="/app/SoliDiffy/tree-sitter-parser:$PATH"

# Expose the SoliDiffy.sh script as a command
WORKDIR /app/SoliDiffy
# Make the script executable
RUN chmod +x /app/SoliDiffy/SoliDiffy.sh

# Use ENTRYPOINT to ensure all arguments go to SoliDiffy.sh
ENTRYPOINT ["/bin/bash", "/app/SoliDiffy/SoliDiffy.sh"]


