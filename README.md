# Website Guardiões da Biodiversidade

## Requisitos

* PostgreSQL (v11.1) com a extensão postgis habilitada
* ImageMagick (v6.7.8-9)
* Sendmail
* Perl (v5.16.3)
* Módulo Perl DBD::Pg
* Módulo Perl Image::Magick
* Módulo Perl Mail::Sendmail
* Módulo Perl JSON
* Módulo Perl MIME::Base64
* Módulo Perl Digest::SHA1
* Módulo Perl Data::Dumper
* Módulo Perl Excel::Writer::XLSX
* Módulo Perl Net::Facebook::Oauth2 (login no Facebook)
* Módulo Perl Net::OAuth2::Profile::WebServer (login no Google)
* Módulo Perl Net::Twitter (login no Twitter)
* Módulo Perl WebService::Instagram (login no Instagram)

## Instalação

Depois de instalar os programas acima, descompacte o arquivo contendo o código fonte:

```
tar xvzf guardioes-src.tar.gz
```

Crie um diretório "html" e dentro dele um link simbólico para o diretório "users":

```
cd guardioes
mkdir html
cd html
ln -s ../users users 
```

Faça as alterações necessárias no seu servidor web de forma que o conteúdo dos diretórios 
docs e html fiquem acessíveis e que os scripts Perl funcionem (no caso do Apache,
instale e habilite o mod-perl).

Crie os bancos de dados e rode o script com as definições do esquema de cada um:

```
createdb guardioes
createdb guardioes_api
createdb guardioes_log
createdb sp_dic
psql guardioes
\i guardioes-schema.pgdump
\c guardioes_api
\i guardioes_api-schema.pgdump
\c guardioes_log
\i guardioes_log-schema.pgdump
\c sp_dic
\i sp_dic-schema.pgdump
```
Obs: O dicionário de dados contendo descrição das tabelas e campos encontra-se no arquivo dd.md

Renomeie o arquivo lib/CFG_blank.pm para CFG.pm, em seguida editando 
o arquivo para colocar todas as configurações necessárias (acesso ao banco, diretórios, etc.)

Observe que para que o login através de redes sociais funcione é necessário obter uma chave de
API para cada uma delas: Facebook, Twitter, Instagram e Google. Além disso é necessária uma
chave de API para usar o Google Maps.

```
cp lib/CFG_blank.pm lib/CFG.pm
vim lib/CFG.pm
```

Reinicie seu servidor web e teste.

# APISRV

Serviço/API responsável pela comunicação com o aplicativo móvel

Utiliza o banco de dados posgresql guardioes_api

Documentação disponível ao abrir o próprio script pelo navegador: apisrv



