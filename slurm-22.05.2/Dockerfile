FROM --platform=linux/amd64 opensuse/leap:15.3

ARG SLURM_VERSION=22.05.2
ARG SLURM_ROOT=/opt/slurm-${SLURM_VERSION}
ARG SLURM_CONFDIR=${SLURM_ROOT}/etc

ENV SLURM_VERSION   ${SLURM_VERSION}
ENV SLURM_ROOT      ${SLURM_ROOT}
ENV SLURM_CONFDIR   ${SLURM_CONFDIR}


RUN zypper install -y       \
    nano		    \
    munge                   \
    munge-devel             \
    libnuma1                \
    libnuma-devel           \
    librrd8                 \
    readline-devel          \
    hwloc                   \
    hwloc-devel             \
    hdf5                    \
    hdf5-devel              \
    lz4                     \
    liblz4-devel            \
    libz1                   \
    zlib-devel              \
    freeipmi                \
    freeipmi-devel          \
    dbus-1                  \
    dbus-1-devel            \
    make                    \
    gcc                     \
    gcc-c++                 \
    curl                    \
    tar                     \
    bzip2                   \
    python3                 \
    vim                     \
    mariadb-server          \
    libmariadb-devel        \
    ca-certificates         \
    less                    \
    mpich                   \
    mpich-devel             \
    sudo

RUN zypper install -y       \
    lua53                   \
    lua53-devel             \
    libmount-devel

RUN zypper install -y python3-pip

RUN useradd -M slurm

RUN mkdir -p /var/log/slurm && chown slurm /var/log/slurm
RUN mkdir -p /var/spool/slurmctld && chown slurm /var/spool/slurmctld && chmod u+rwx /var/spool/slurmctld
RUN mkdir -p /var/spool/slurmd    && chown slurm /var/spool/slurmd    && chmod u+rwx /var/spool/slurmd

RUN mkdir -p /var/lib/mysql /var/log/mariadb /var/run/mariadb
#configure mysqld
#RUN chmod g+rw /var/lib/mysql /var/log/mariadb /var/run/mariadb && \
    #mysql_install_db && \
#    mysql_install_db --user=mysql --basedir=/usr --datadir=/var/libmysql && \
#    chown -R mysql:mysql /var/lib/mysql

RUN chmod g+rw /var/lib/mysql /var/log/mariadb /var/run/mariadb && \ 
    mysql_install_db --auth-root-authentication-method=normal && \ 
    chown -R mysql:mysql /var/lib/mysql /var/log/mysql /var/log/mariadb /var/run/mariadb && \
	ls -ld /var/lib/mysql	/var/log/mysql /var/run/mariadb && \
	ls -l /var/lib/mysql	/var/log/mysql /var/run/mariadb 
RUN mysqld_safe & mysqladmin --silent --wait=30 ping && \
	mysql -e 'DELETE FROM mysql.user WHERE user NOT LIKE "root";'  && \
    mysql -e 'DELETE FROM mysql.user WHERE Host NOT IN ("localhost","127.0.0.1","%");' && \ 
#    mysql -e 'GRANT ALL PRIVILEGES ON *.* TO "root"@"%" WITH GRANT OPTION;' && \ 
    mysql -e 'GRANT ALL PRIVILEGES ON *.* TO "root"@"localhost" WITH GRANT OPTION;' && \ 
    mysql -e 'CREATE USER "slurm"@"localhost" IDENTIFIED BY "slurm";' && \ 
    mysql -e 'CREATE USER "slurm"@"%" IDENTIFIED BY "slurm";' && \ 
    mysql -e 'GRANT ALL PRIVILEGES ON *.* TO "slurm"@"%" WITH GRANT OPTION;' && \ 
    mysql -e 'GRANT ALL PRIVILEGES ON *.* TO "slurm"@"localhost" WITH GRANT OPTION;' && \ 
    mysql -e 'DROP DATABASE IF EXISTS test;' && \ 
    mysqladmin shutdown

COPY install_slurm.sh .

RUN  ./install_slurm.sh ${SLURM_VERSION} ${SLURM_ROOT} ${SLURM_CONFDIR} --enable-multiple-slurmd

RUN  mkdir -p         ${SLURM_CONFDIR}
COPY cgroup.conf      ${SLURM_CONFDIR}
COPY slurm.conf.in    ${SLURM_CONFDIR}
#COPY slurm.conf       ${SLURM_CONFDIR}
#COPY slurmdbd.conf    ${SLURM_CONFDIR}
COPY slurmdbd.conf.in ${SLURM_CONFDIR}


#RUN chmod 600 ${SLURM_CONFDIR}/slurmdbd.conf
#RUN chown slurm ${SLURM_CONFDIR}/slurmdbd.conf

COPY entrypoint.sh .
ENTRYPOINT ["./entrypoint.sh"]

RUN ls -l ${SLURM_CONFDIR}
#RUN cat ${SLURM_CONFDIR}/slurmdbd.conf

CMD ["bash"]

#COPY run_slurm_examples example.job mpi_example.job plugin.cpp mpi_hello.c .
RUN mkdir -p /home/spack/
RUN mkdir -p /home/spack/log
RUN chmod -R 777 /home/spack/
RUN chmod -R 777 /home/spack/log
COPY script_create_users_and_groups.py script_create_slurm_users_and_accounts.py create_slurm_jobs.py /home/spack/
COPY slurm_anon_epyc64_10days /home/spack/
COPY restart_slurmd.sh /home/spack/
COPY example_job.sh /home/spack/
COPY fix_slurm_conf.sh /home/spack/
COPY my.cnf /etc
RUN pip install pandas
RUN cd /home/spack && python3 script_create_slurm_users_and_accounts.py && python3 script_create_users_and_groups.py
RUN source /home/spack/create_users_and_groups.sh || true
#RUN source /home/spack/create_slurm_users_and_accounts.sh || true
RUN echo "Step 1, Run: docker run --detach --rm -it -e SLURM_NUMNODES=171 slurm-22.05.2"
RUN echo "Step 2, Run: docker attach dockerid"
RUN echo "Step 3, Run: sh /home/spack/fix_slurm_conf.sh"
