# setup asdf
function Setup-Asdf {
    param (
        [string]$RepoUrl = "https://github.com/asdf-vm/asdf.git",
        [string]$TargetDir = "$HOME\.asdf",
        [string]$Branch = "v0.14.0"
    )

    git clone $RepoUrl $TargetDir --branch $Branch

    if (-Not (Test-Path -Path "$TargetDir\asdf.ps1")) {
        Write-Error "Failed to clone the repository or the script file is missing."
        return
    }
    . "$TargetDir\asdf.ps1"

    Write-Output "asdf has been set up successfully."
}

$userResponse = Read-Host "Do you want to install asdf? (y/n)"

if ($userResponse -eq 'y') {
    Setup-Asdf

    $asdfVersion = asdf --version
    if ($asdfVersion) {
        Write-Output "asdf version: $asdfVersion"
    } else {
        Write-Error "Failed to retrieve asdf version. Please check the installation."
    }
} else {
    Write-Output "Installation of asdf was skipped."
}

# setup AWS profile in .env file
function Setup-AWSProfile {
    $envChoice = Read-Host "Do you want to set up .env? (y/n) [y]"
    $envChoice = if ($envChoice -eq "") { "y" } else { $envChoice }

    switch ($envChoice.ToLower()) {
        "y" {
            if (Test-Path -Path ".env") {
                $overwriteChoice = Read-Host "The .env file already exists. Are you sure you want to overwrite it? (y/n) [n]"
                $overwriteChoice = if ($overwriteChoice -eq "") { "n" } else { $overwriteChoice }

                switch ($overwriteChoice.ToLower()) {
                    "y" {
                        Remove-Item -Path ".env" -Force
                        Configure-AWSProfile
                    }
                    default {
                        Write-Host "Keeping the existing .env file."
                    }
                }
            } else {
                Configure-AWSProfile
            }
        }
        "n" {}
        default {
            Write-Host "Invalid input. Please enter y or n."
            exit 1
        }
    }
}

function Configure-AWSProfile {
    Write-Host "Configuration for AWS access..."
    $awsAccessKeyId = Read-Host "Enter your AWS Access Key ID"
    $awsSecretAccessKey = Read-Host "Enter your AWS Secret Access Key"
    $awsRegion = Read-Host "Enter your AWS Region [us-east-1]"
    $awsRegion = if ($awsRegion -eq "") { "us-east-1" } else { $awsRegion }

    @"
export AWS_ACCESS_KEY_ID=$awsAccessKeyId
export AWS_SECRET_ACCESS_KEY=$awsSecretAccessKey
export AWS_REGION=$awsRegion
export AWS_DEFAULT_REGION=$awsRegion
"@ | Out-File -FilePath ".env" -Encoding ascii

    Write-Host ".env file created/overwritten successfully."
}

Setup-AWSProfile

# setup project with asdf
function Setup-AsdfProject {
    $asdfSetupChoice = Read-Host "Do you want to setup project with asdf? (y/n) [y]"
    $asdfSetupChoice = if ($asdfSetupChoice -eq "") { "y" } else { $asdfSetupChoice }

    switch ($asdfSetupChoice.ToLower()) {
        "y" {
            Write-Host "Setting up project with asdf..."

            Get-Content .tool-versions | ForEach-Object {
                $tool = $_ -split ' ')[0]
                asdf plugin add $tool
            }

            Invoke-Expression "$(asdf exec direnv hook bash)"
            asdf direnv setup --shell zsh --version latest
            asdf direnv install
            asdf exec direnv allow
        }
        "n" {}
        default {
            Write-Host "Invalid input. Please enter y or n."
            exit 1
        }
    }
}

Setup-AsdfProject

# setup Python virtual environment
function Setup-PythonVenv {
    $pythonVenvChoice = Read-Host "Do you want to set up python venv? (y/n) [y]"
    $pythonVenvChoice = if ($pythonVenvChoice -eq "") { "y" } else { $pythonVenvChoice }

    switch ($pythonVenvChoice.ToLower()) {
        "y" {
            Write-Host "Setting up python venv..."
            python -m venv .venv
            .\.venv\Scripts\Activate.ps1
            pip install -r requirements.txt
        }
        "n" { return }
        default {
            Write-Host "Invalid input. Please enter y or n."
            return
        }
    }
}

Setup-PythonVenv

# setup terraform
$terraformInitChoice = Read-Host "Do you want to run 'terraform init'? (y/n) [y]"
$terraformInitChoice = if ($terraformInitChoice -eq "") { "y" } else { $terraformInitChoice }

switch ($terraformInitChoice.ToLower()) {
    "y" {
        Write-Host "Running 'terraform init'..."
        terraform init
    }
    "n" { return }
    default {
        Write-Host "Invalid input. Please enter y or n."
        return
    }
}

Write-Host "Setup completed successfully."