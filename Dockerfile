FROM armbuild/debian
MAINTAINER Thomas Langewouters <ignoreuntilafterthedot.thomas.langewouters@thouters.be>
# run with docker run -it --rm  -p 0.0.0.0:3000:3000 -v tracks.db:/var/www/tracks

RUN apt-get update

RUN apt-get install -yqq \
    ruby \
    rubygems-integration \
    bundler \
    sqlite3 \
    libsqlite3-dev \
    build-essential \
    curl \
    unzip 

RUN apt-get install -yqq libmysqlclient-dev
RUN useradd tracks

ENV DEBIAN_FRONTEND noninteractive
ADD ./v2.3.0.zip.sha1 /var/www/
RUN cd /var/www \
    && wget https://github.com/TracksApp/tracks/archive/v2.3.0.zip \
    && sha1sum --status -c v2.3.0.zip.sha1 \
    && unzip v2.3.0.zip \
    && mv tracks-2.3.0 tracks  \
    && chown -R tracks:tracks tracks \
    && rm v2.3.0.zip v2.3.0.zip.sha1

RUN cd /var/www/tracks \
    && gem install rake -v 10.4.2 \
    && bundle install
#RUN rm /var/www/tracks/Gemfile
ADD ./database.yml /var/www/tracks/config/
ADD ./site.yml /var/www/tracks/config/

#TODO: move tracks.db to a volume.
ADD ./tracks.db /var/www/tracks/db/tracks.db
RUN chown tracks:tracks /var/www/tracks/db/tracks.db

RUN sed -i 's/config.serve_static_assets = false/config.serve_static_assets = true/' /var/www/tracks/config/environments/production.rb

RUN cd /var/www/tracks \
    && export RAILS_ENV=production \
    && su tracks -c 'bundle exec rake db:migrate RAILS_ENV=production' \
    && su tracks -c 'bundle exec rake assets:precompile RAILS_ENV=production'

EXPOSE 3000 
USER tracks
WORKDIR /var/www/tracks
CMD ["/usr/bin/bundle","exec","rails","server","-e","production","-b","0.0.0.0"]
