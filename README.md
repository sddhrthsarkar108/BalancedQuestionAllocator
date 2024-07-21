## Pre-Requisites
- AWS account
- Code Editor (vscode / intellij)

## Setup
### zsh (linux/mac)
```sh
./setup.sh
```

### powershell (windows)
```powershell
.\setup.ps1
```

## Project Structure
- `infrastructure` - terraform code for managing AWS resources
- `lambda` - application code
- `notebook` - Jupyter notebook for expermental development
- `.env` - environment variables required for local development
- `.tools-version` - software required for development
- `requirement.txt` - python packages required for local development
- `rest_calls.http` - rest client call definations (required to install `REST Clinet` extention for `vscode` IDE)

## Infrastructure
### To verify changes
```sh
cd infrastructure && terraform plan
```

### To apply changes
```sh
cd infrastructure && terraform apply --auto-approve
```