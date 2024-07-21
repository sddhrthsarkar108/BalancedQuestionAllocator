#!/bin/zsh

# Install asdf
setup_asdf() {
    echo -n "Do you want to install asdf? (y/n) [y]: "
    read asdf_choice
    asdf_choice=${asdf_choice:-"y"}
    case "$asdf_choice" in
      y|Y )
          if command -v asdf &>/dev/null; then
            echo "asdf is already installed."
          else
            echo "Cloning asdf repository..."
            git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.0 || { echo "Error: Failed to clone asdf repository." >&2; return; }

            echo "Appending configurations to .zshrc..."
            echo -e "\n# -- ASDF --\n. \"$HOME/.asdf/asdf.sh\"\n\n# append completions to fpath\nfpath=(${ASDF_DIR}/completions \$fpath)\n# initialise completions with ZSH's compinit\nautoload -Uz compinit && compinit\n# -- ASDF --\n" >> ~/.zshrc || { echo "Error: Failed to append configurations to .zshrc." >&2; return; }
            source ~/.zshrc
            echo "asdf installed successfully."
          fi
          ;;
      n|N ) ;;
      * ) echo "Invalid input. Please enter y or n.";;
    esac
}

setup_asdf

# Setup aws profile
echo -n "Do you want to set up .env? (y/n) [y]: "
read env_choice
env_choice=${env_choice:-"y"}
case "$env_choice" in
  y|Y )
      if [ -f .env ]; then
          echo -n "The .env file already exists. Are you sure you want to overwrite it? (y/n) [n]: "
          read overwrite_choice
          overwrite_choice=${overwrite_choice:-"n"}
          case "$overwrite_choice" in
              y|Y )
                  rm -f .env
                  echo "Configuration for AWS access..."
                  echo -n "Enter your AWS Access Key ID: "
                  read aws_access_key_id
                  echo -n "Enter your AWS Secret Access Key: "
                  read aws_secret_access_key
                  echo -n "Enter your AWS Region [us-east-1]: "
                  read aws_region
                  aws_region=${aws_region:-"us-east-1"}
cat <<EOF > .env
export AWS_ACCESS_KEY_ID=$aws_access_key_id
export AWS_SECRET_ACCESS_KEY=$aws_secret_access_key
export AWS_REGION=$aws_region
export AWS_DEFAULT_REGION=$aws_region
EOF
                  echo ".env file overwritten successfully."
                  ;;
              * )
                  echo "Keeping the existing .env file."
                  ;;
          esac
      else
      echo "Configuration for AWS access..."
      echo -n "Enter your AWS Access Key ID: "
      read aws_access_key_id
      echo -n "Enter your AWS Secret Access Key: "
      read aws_secret_access_key
      echo -n "Enter your AWS Region [us-east-1]: "
      read aws_region
      aws_region=${aws_region:-"us-east-1"}
cat <<EOF > .env
export AWS_ACCESS_KEY_ID=$aws_access_key_id
export AWS_SECRET_ACCESS_KEY=$aws_secret_access_key
export AWS_REGION=$aws_region
export AWS_DEFAULT_REGION=$aws_region
EOF
      echo ".env file created successfully."
      fi
      ;;
  n|N ) ;;
  * ) echo "Invalid input. Please enter y or n."; exit 1;;
esac

echo -n "Do you want to setup project with asdf? (y/n) [y]: "
read asdf_setup_choice
asdf_setup_choice=${asdf_setup_choice:-"y"}
case "$asdf_setup_choice" in
  y|Y )
      echo "Setting up project with asdf..."
      cat .tool-versions | awk '{print $1}' | xargs -I _ asdf plugin add _
      eval "$(asdf exec direnv hook bash)"
      asdf direnv setup --shell zsh --version latest
      asdf direnv install
      asdf exec direnv allow
      ;;
  n|N ) ;;
  * ) echo "Invalid input. Please enter y or n."; exit 1;;
esac

# Setup python venv
setup_python_venv() {
    echo -n "Do you want to set up python venv? (y/n) [y]: "
    read python_venv_choice
    python_venv_choice=${python_venv_choice:-"y"}
    case "$python_venv_choice" in
      y|Y ) ;;
      n|N ) return;;
      * ) echo "Invalid input. Please enter y or n."; return;;
    esac
    echo "Setting up python venv..."
    python3 -m venv .venv
    source .venv/bin/activate
    pip3 install -r requirements.txt
}

setup_python_venv

# setup terraform
echo -n "Do you want to run 'terraform init'? (y/n) [y]: "
read terraform_init_choice
terraform_init_choice=${terraform_init_choice:-"y"}
case "$terraform_init_choice" in
  y|Y )
      echo "Running 'terraform init'..."
      cd infrastructure
      terraform init
      cd ..
      ;;
  n|N ) ;;
  * ) echo "Invalid input. Please enter y or n."; exit 1;;
esac

echo "Setup completed successfully."