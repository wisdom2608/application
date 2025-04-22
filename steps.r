How to generate Docker DOCKER_PASSWORD

- go to Docker
- click on username
- click on Account Settings
- click on Personal Access Tokens
- click on New Access Token
under Expiration date,  select 'none'
uder Access permissions, select 'Read & Write' permission, and 
click on 'Generate'


Go back to the github Access for the same repository and click on 'Settings'
- click on 'Secrets and variables'
- click on 'Actions'
- click on 'New repository secret'
- under Name, type DOCKER_PASSWORD
- under Value, paste the token you generated in the previous step
- click on 'Add secret'

###################
name: Test and Build

on:
  push:
    branches:
      - master
    paths:
      - '**/*'

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    #Setting up environment
      - name: Checkout code
        uses: actions/checkout@v2

      - name: Setup Python
        uses: actions/setup-python@v2
        with:
          python-version: '3.9'

      - name: Docker Setup
        uses: docker/setup-buildx-action@v2

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt
          pip install flake8
          
      # Test the Code
      - name: Run Linting tests
        run: |
          flake8 --ignore=E501,F401 .
      
      - name: Docker Credentials
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}
      
      - name: Docker tag
        id: version
        run: |
          VERSION=v$(date +"%Y%m%d%H%M%S")
          echo "VERSION=$VERSION" >> $GITHUB_ENV

      # Build the Docker Image
      - name: Build Docker Image
        run: |
          docker build . -t 1nfosecsingh/demo-app:${{ env.VERSION }} 
      
      # Push the Docker Image
      - name: Push Docker Image
        run: |
          docker push 1nfosecsingh/demo-app:${{ env.VERSION }}
      
      # UPdate the K8s Manifest Files
      - name: Update K8s Manifests
        run: |
          cat deploy/deploy.yaml
          sed -i "s|image: 1nfosecsingh/demo-app:.*|image: 1nfosecsingh/demo-app:${{ env.VERSION }}|g" deploy/deploy.yaml
          cat deploy/deploy.yaml

      # Update Github
      - name: Commit the changes
        run: |
          git config --global user.email "<>"
          git config --global user.name "GitHub Actions Bot"
          git add deploy/deploy.yaml
          git commit -m "Update deploy.yaml with new image version - ${{ env.VERSION }}"
          git remote set-url origin https://github-actions:${{ secrets.GITHUB_TOKEN }}@github.com/infosecsingh/Flask-App-GitHub-Actions-ArgoCD.git
          git push origin master

##################################