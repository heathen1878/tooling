# Tooling

[![Built with Devbox](https://www.jetify.com/img/devbox/shield_galaxy.svg)](https://www.jetify.com/devbox/docs/contributor-quickstart/)

This repo contains the infrastructure that is required to bootstrap Terraform for all the other repositories which contain Terraform code examples.

The setup is as follows:

1. Install DevBox

```shell
curl -fsSL https://get.jetify.com/devbox | bash
```

2. Start DevBox

```shell
devbox shell
```

```shell
{
    echo alias tfapply='source ~/source/tooling/scripts/apply.sh'
    echo alias tfauth='source ~/source/tooling/scripts/auth.sh'
    echo alias tfdestroy='source ~/source/tooling/scripts/destroy.sh'
    echo alias tfimport='source ~/source/tooling/scripts/import.sh'
    echo alias tfinit='source ~/source/tooling/scripts/init.sh'
    echo alias tfoutput='source ~/source/tooling/scripts/output.sh'
    echo alias tfplan='source ~/source/tooling/scripts/plan.sh'
    echo alias tfset='source ~/source/tooling/scripts/setup.sh'
} >> ~/.bash_aliases
```

3. Set bashrc to dot source the functions required by the aliases above

```shell
~/.bashrc << EOF
if [ -d ~/source/tooling/functions ]
    then
    for f in ~/source/tooling/functions/*.sh
        source $f
    done
fi
EOF
```

4. 
