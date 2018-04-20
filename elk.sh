#!/bin/bash

echo "------------------------------------------------------"
echo "            Reverse proxied ELK setup wizard          "
echo "------------------------------------------------------"
cat art.txt

ELK_PGP_KEY="https://artifacts.elastic.co/GPG-KEY-elasticsearch"

# Importing pgp key
echo -e "\e[36mImporting Elasticsearch pgp key\e[m"
rpm --import $ELK_PGP_KEY || echo -e "\e[91mError importing pgp key\e[m"

export yum_repo_path="/etc/yum.repos.d/"

function install_java {
    if [[ $(type -p java) ]]
    then
       echo -e "\e[36mJava is already installed. Checking version.\e[m"
       JAVA_VER=$(java -version 2>&1 | sed -n ';s/.* version "\(.*\)\.\(.*\)\..*"/\1\2/p;')
       if [[ "${JAVA_VER}" -le 18 && ! -d /usr/lib/java-1.8.0 ]]
       then
          echo -e "\e[31mElasticsearch requires at least java version 8.\e[m"
          echo -e "\e[36mInstalling java 1.8.0\e[m"
          yum install -y java-1.8.0
          /usr/sbin/alternatives --config java
       fi
    else
       echo -e "\e[36mInstalling java 1.8.0\e[m"
       yum install -y java-1.8.0
    fi
    echo -e "\e[32mJava is of required version. Nothing needs to be done.\e[m"

}

function setup_es {
    echo "${yum_repo_path}"
    es_repo_file="${yum_repo_path}elasticsearch.repo"

    # Adding ES repo to yum repos list
    echo -e "\e[36mChecking if older ES version repository details are present in /etc/yum.repos.d\e[m"

    if [[ -f "${es_repo_file}" && -s "${es_repo_file}" ]]
    then
        [[ -z $(grep 'elasticsearch-6.x' ${es_repo_file}) ]] \
        && echo -e "\e[31mRepository file already exists and is of older ES version. Removing the file.\e[m" \
        && echo -e "\e[36mAdding ES 6.x repo details to yum repos\e[m" || \
        echo "\e[32mFile is updated and has 6.x version.\e[m"
    elif [[ ! -f "${es_repo_file}" ]]
    then
        echo -e "\e[36mNo prior ES repository file exists\e[m"
        echo -e "\e[36mAdding ES 6.x repo details to yum repos\e[m"
        cp ${PWD}/elasticsearch.repo "${yum_repo_path}" || exit
    else
        echo -e "\e[91mAn empty file with name elasticsearch.repo exists. Removing the file\e[m"
        echo -e "\e[36mAdding ES 6.x repo details to yum repos\e[m"
        echo "${yum_repo_path}"
        ls ${PWD}/elasticearch.repo
        cp ${PWD}/elasticsearch.repo "${yum_repo_path}" || exit
    fi

    # Install ES
    echo -e "\e[36mInstalling Elasticsearch-6.x\e[m"
    yum install -y elasticsearch
    echo -e "\e[32mInstallation of ES is complete.\e[m"

    sys=$(ps -p 1 | awk -F ' ' 'NR==2 {print $4}')
    echo "${sys}"
    if [[ $sys = 'init' ]]
    then
       echo -e "\e[36mGearing up ES for automatically start on system boots up.\e[m"
       chkconfig --add elasticsearch
       echo -e "\e[36mStarting ElasticSearch\e[m"
       service elasticsearch start && echo -e "[32mStarted.\e[m"
    fi

    if [[ $sys = 'systemd' ]]
    then
       echo -e "\e[36mGearing up ES for automatically start on system boots up.\e[m"
       /bin/systemctl daemon-reload
       /bin/systemctl enable elasticsearch.service
       echo -e "\e[36mStarting ElasticSearch\e[m"
       systemctl start elasticsearch.service
    fi
}

function setup_ls {
    ls_repo_file="${yum_repo_path}logstash.repo"

    # Adding LS repo to yum repos list
    echo -e "\e[36mChecking if older LS version repository details are present in /etc/yum.repos.d\e[m"

    if [[ -f "${ls_repo_file}" && -s "${ls_repo_file}" ]]
    then
        [[ -z $(grep 'logstash-6.x' ${ls_repo_file}) ]] \
        && echo -e "\e[31mRepository file already exists and is of older LS version. Removing the file.\e[m" \
        && echo -e "\e[36mAdding LS 6.x repo details to yum repos\e[m" || \
        echo -e "\e[32mFile is updated and has 6.x version.\e[m"
    elif [[ ! -f "${ls_repo_file}" ]]
    then
        echo -e "\e[36mNo prior LS repository file exists\e[m"
        echo -e "\e[36mAdding LS 6.x repo details to yum repos\e[m"
        cp ${PWD}/logstash.repo "${yum_repo_path}"
    else
        echo -e "\e[91mAn empty file with name logstash.repo exists. Removing the file\e[m"
        echo -e "\e[36mAdding LS 6.x repo details to yum repos\e[m"
        cp ${PWD}/logstash.repo "${yum_repo_path}"
    fi

    # Install LS
    echo -e "\e[36mInstalling Logstash-6.x\e[m"
    yum install -y logstash && echo -e "\e[32mInstallation of LS is complete.\e[m"


    [[ ! -z $(uname -r | grep amzn) ]] \
    && echo -e "\e[36mStarting Logstash\e[m" \
    && initctl start logstash \
    && return \
    
    sys=$(ps -p 1 | awk -F ' ' 'NR==2 {print $4}')
    echo "${sys}"
    if [[ $sys = 'init' ]]
    then
       echo -e "\e[36mGearing up LS for automatically start on system boots up.\e[m"
       chkconfig --add logstash
       echo -e "\e[36mStarting Logstash\e[m"
       service logstash start && echo -e "[32mStarted.\e[m"
    fi

    if [[ $sys = 'systemd' ]]
    then
       echo -e "\e[36mGearing up LS for automatically start on system boots up.\e[m"
       /bin/systemctl daemon-reload
       /bin/systemctl enable logstash.service
       echo -e "\e[36mStarting Logstash\e[m"
       systemctl start logstash.service
    fi
}

function setup_kibana {
    kb_repo_file="${yum_repo_path}kibana.repo"

    # Adding LS repo to yum repos list
    echo -e "\e[36mChecking if older Kibana version repository details are present in /etc/yum.repos.d\e[m"

    if [[ -f "${kb_repo_file}" && -s "${kb_repo_file}" ]]
    then
        [[ -z $(grep 'kibana-6.x' ${kb_repo_file}) ]] \
        && echo -e "\e[31mRepository file already exists and is of older kibana version. Removing the file.\e[m" \
        && echo -e "\e[36mAdding kibana 6.x repo details to yum repos\e[m" \
        || echo -e "\e[32mFile is updated and is of latest version.\e[m"
    elif [[ ! -f "${kb_repo_file}" ]]
    then
        echo -e "\e[36mNo prior Kibana repository file exists\e[m"
        echo -e "\e[36mAdding Kibana 6.x repo details to yum repos\e[m"
        cp ${PWD}/kibana.repo "${yum_repo_path}"
    else
        echo -e "\e[91mAn empty file with name kibana.repo exists. Removing the file\e[m"
        echo -e "\e[36mAdding Kibana 6.x repo details to yum repos\e[m"
        cp ${PWD}/kibana.repo "${yum_repo_path}"
    fi

    # Install Kibana
    echo -e "\e[36mInstalling kibana-6.x\e[m"
    yum install -y kibana && echo -e "\e[32mInstallation of kibana is complete.\e[m"

    sys=$(ps -p 1 | awk -F ' ' 'NR==2 {print $4}')
    echo "${sys}"
    if [[ $sys = 'init' ]]
    then
       echo -e "\e[36mGearing up Kibana for automatically start on system boots up.\e[m"
       chkconfig --add kibana
       echo -e "\e[36mStarting Kibanash\e[m"
       service kibana start && echo -e "[32mStarted.\e[m"
    fi

    if [[ $sys = 'systemd' ]]
    then
       echo -e "\e[36mGearing up Kibana for automatically start on system boots up.\e[m"
       /bin/systemctl daemon-reload
       /bin/systemctl enable kibana.service
       echo -e "\e[36mStarting Kibana\e[m"
       systemctl start kibana.service
    fi
}

function setup_nginx {
    htpasswd_file="/etc/nginx/.htpasswd"
    echo -e "\e[36mSetting up nginx reverse proxy\e[m"
    echo -e "\e[36mInstalling epel repo and nginx\e[m"
     yum install -y epel-release &&  yum install -y nginx
    echo -e "\e[36mStarting nginx\e[m"
     systemctl start nginx &&  systemctl enable nginx
    echo -e "\e[36mInstalling and configuring httpd-tools.\e[m"
     yum install -y httpd-tools
    [[ ! -z $(yum list installed httpd-tools  | awk 'NR==3 {print $1}' > /dev/null 2>&1) ]] \
    && echo -e "\e[32mhttpd-tools are already installed.\e[m" \
    || echo -e "\e[36mInstalling and configuring httpd-tools\e[m" \
    &&  yum install -y httpd-tools
    echo -e "\e[36mCreating username and passwords to authentication.\e[m"

    if [[ -f "${htpasswd_file}" ]]
    then
       echo -e "\e[33mDefault htpasswd file already exists.\e[m"
       echo -e "\e[33mNewly created credentials will be appended to the same file.\e[m"
       [[ ! -z $(grep 'kibanaadm' ${htpasswd_file}) ]] \
       && echo -e "\e[36mDefault user is already present in the file. Autogenerating username.\e[m" \
       && autogen_uname=$(tr -dc a-z0-9_ < /dev/urandom | head -c 10) \
       || autogen_uname="kibanaadm"
       autogen_pwd=$(tr -dc a-z0-9_ < /dev/urandom | head -c 10)
       htpasswd -cb "${htpasswd_file}" kibanaadm $autogen_pwd
       echo -e "\e[32mUser: $autogen_uname\e[m"
       echo -e "\e[32mPassword: $autogen_pwd\e[m"
    else
       echo -e "\e[36mGenerating auth file with credentials at ${htpasswd_file}\e[m"
       touch "${htpasswd_file}" \
       || echo -e "\e[31mUnable to create http authentication file\e[m"
       autogen_uname="kibanaadm"
       autogen_pwd=$(tr -dc a-z0-9_ < /dev/urandom | head -c 10)
       htpasswd -cb "${htpasswd_file}" kibanaadm $autogen_pwd
       echo -e "\e[32mUser: $autogen_uname\e[m"
       echo -e "\e[32mPassword: $autogen_pwd\e[m"
    fi

    # Adding nginx config for setting reverse proxy
    kibana_conf_file="/etc/nginx/conf.d/kibana.conf"
    if [[ -f "${kibana_conf_file}" ]]
    then
       echo -e "\e[31mA file with the name kibana.conf already exists\e[m."
       echo -e "\e[31mDo you want to continue overwriting the file? Please enter Y/y or N/n."
       read choice
       case "${choice}" in
           y|Y ) cp ${PWD}/kibana.conf "${kibana_conf_file}" || echo -e "\e[31mError copying the file\e[m" ;;
           n|N ) echo -e "\e[31mExiting\e[m" && exit  ;;
           * ) echo "Invalid choice. Exiting." && exit ;;
       esac
    else
       cp ${PWD}/kibana.conf "${kibana_conf_file}" || echo -e "\e[31mError creating kibana config file\e[m" && exit
    fi

    # Check nginx config errors and restart
    echo -e "[36mTesting aad restarting nginx config.\e[m"
    sys=$(ps -p 1 | awk -F ' ' 'NR==2 {print $4}')
    echo "${sys}"
    if [[ "${sys}" = 'init' ]]
    then
       echo -e "\e[36mRestarting nginx service\e[m"
       service nginx configtest &&  service nginx reload
    fi

    if [[ $sys = 'systemd' ]]
    then
       echo -e "\e[36mRestarting nginx service\e[m"
       systemctl restart nginx.service
    fi

}

function modify_kibana_config {
    kibana_config_path="/etc/kibana/kibana.yml"
    sed -i 's;#server.basePath: "";server.basePath: "/kibana";g' ${kibana_config_path} \
    || echo -e "\e[31mError while replacing the basePath in kibana. Exiting.\e[m" && exit

    sys=$(ps -p 1 | awk -F ' ' 'NR==2 {print $4}')
    echo "${sys}"
    if [[ $sys = 'init' ]]
    then
       echo -e "\e[36mRestarting kibana service\e[m"
       service kibana restart && echo -e "[32mRestarted.\e[m"
    fi

    if [[ $sys = 'systemd' ]]
    then
       echo -e "\e[36mRestarting kibana service\e[m"
       systemctl restart kibana.service
    fi

}

install_java

setup_es

setup_ls

setup_kibana

setup_nginx

modify_kibana_config
