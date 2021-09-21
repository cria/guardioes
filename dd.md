# Dicionário de Dados do Sistema Guardiões da Biodiversidade
# Banco: guardioes

Banco de dados principal do sistema.

## Tabela: counts

Armazena contadores gerais do sistema como número de registros, identificações, imagens, etc., por usuário e totais. É atualizada através de trigger sempre que tabelas envolvidas nos números são alteradas.
Campo | Tipo | Descrição
--- | --- | ---
**user_id** | integer | Chave do usuário (0 para estatísticas globais).
**key** | text | Tipo de contador.<br>Tabela atualizada por trigger com a função updateCounts().<br>num_ident = número de identificações por reino e total<br>num_image = número de imagens por reino, usuário e total<br>num_rec = número de registros por usuário e total<br>num_user = número de usuários por categoria e total<br>idents_by = número total de identificações feitas por usuário e reino<br>pub_idents_by = número de identificações atuais (current id) por usuário e reino<br>rec_noid = número de registros sem identificação por reino, usuário e grupo taxonômico<br>rec_noval = número de registros que têm identificações aguardando validação, por usuário, reino, grupo taxonômico e total<br>spp_id = número de espécies identificadas nos registros enviados pelo usuário por usuário, reino e grupo taxonômico
**kingdom** | text | Todos os contadores da tabela são feitas para plantas ou animais envolvidos. O campo kingdom define a qual dos reinos se refere o contador
**taxgrp** | text | Identifica contadores por expertise de especialistas (vide tabela def_expertise)
**num** | integer | Total de registros.

## Tabela: def_expertise

Definições dos grupos de atuação válidos para especialistas cadastrados no sistema.
Campo | Tipo | Descrição
--- | --- | ---
**id** | integer | Chave primária.
**key** | text | Nome do tipo de organismo (planta, formiga, lagarto, etc.).
**grupo** | text | Reino (animalia ou plantae).

## Tabela: def_habit

Definições dos hábitos das plantas válidos.
Campo | Tipo | Descrição
--- | --- | ---
**id** | integer | Chave primária.
**key** | text | Hábito da planta:<br>arvore<br>arbusto<br>erva<br>epifita<br>trepadeira<br>parasita<br>nda

## Tabela: def_interaction

Definições dos tipos de interação animal-planta válidos.
Campo | Tipo | Descrição
--- | --- | ---
**id** | integer | Chave primária.
**key** | text | Tipo de interação:<br>coletando_alimento_flor<br>se_alimentando_fruto<br>construindo_ninho<br>coletando_resina<br>dormindo<br>copulando<br>apoiando<br>comendo_cortando_folhas<br>comendo_cortando_petalas<br>sugando_seiva<br>morando<br>nda
**strength** | integer | 

## Tabela: def_version

Controla modificações feitas nas tabelas def_expertise, def_habit, def_interaction para que sejam atualizadas no app, quando necessário.
Campo | Tipo | Descrição
--- | --- | ---
version | integer | Versão atual das definições.

## Tabela: device

Dispositivo (celular, tablet) utilizado por usuário do sistema.
Campo | Tipo | Descrição
--- | --- | ---
**id** | integer | Chave primária.
**user_id** | integer | Chave do usuário.
**appcode** | text | Código único gerado e fornecido pelo dispositivo.

## Tabela: expertises

Especialidade de usuário do sistema.
Campo | Tipo | Descrição
--- | --- | ---
**user_id** | integer | Chave do usuário.
**expertise_id** | integer | Chave da especialidade.

## Tabela: ident

Identificações dos animais e plantas.
Campo | Tipo | Descrição
--- | --- | ---
**id** | bigint | Chave primária.
record_id | integer | Registro de observação associado.
user_id | integer | Chave do usuário
identifiedby_id | integer | Identificado por.
dateidentified | timestamp with time zone | Data da identificação.
validatedby_id | integer | Validado por.
datevalidated | timestamp with time zone | Data da validação.
scientificname | text | Nome científico.
scientificnameauthorship | text | Autor do nome científico.
kingdom | text | Reino.
phylum | text | Filo.
class | text | Classe.
ordem | text | Ordem.
family | text | Família.
genus | text | Gênero.
subgenus | text | Subgênero.
specificepithet | text | Epíteto específico.
taxonrank | text | Ranking taxonômico.
infraspecificepithet | text | Epíteto infraespecífico.
vernacularname | text | Nome comum.
identificationremarks | text | Observações.
**status** | ident_status_type | Status da identificação: pendente, valido ou invalido..

## Tabela: image

Metadados das imagens associadas aos registros.
Campo | Tipo | Descrição
--- | --- | ---
**id** | integer | Chave primária.
record_id | integer | Registro de observação associado.
user_id | integer | Chave do usuário
**code** | text | Código usado para dar nome a cada imagem enviada
**format** | text | Formato (ex: jpg).
**sequence** | smallint | Sequência da imagem.
**image_of** | image_type | Objeto da imagem: interacao ou planta.

## Tabela: map_projects

Áreas de atuação dos projetos parceiros.
Campo | Tipo | Descrição
--- | --- | ---
**gid** | integer | Chave primária.
id | numeric(10,0) | Identificador (?).
nome | character varying(100) | Nome do projeto.
geom | geometry(MultiPolygon,4326) | Delimitação geográfica.

## Tabela: map_ucsfi

Unidades de Conservação Federais.Unidades de Conservação Federais. Fonte: http://www.icmbio.gov.br/portal/geoprocessamentos/51-menu-servicos/4004-downloads-mapa-tematico-e-dados-geoestatisticos-das-uc-s  opção Unidades de Conservação Federais – SHP (SIRGAS2000), convertida para PostGIS com o comando: "shp2pgsql -s 4326 -I UCs_fed_junho_2018.shp map_ucsfi > map_ucsfi.sql", nomes das UCs transformados com "update map_ucsfi set nome = initcap(nome)".
Campo | Tipo | Descrição
--- | --- | ---
**gid** | integer | Chave primária.
codigocnuc | character varying(15) | Código da UC.
nome | character varying(254) | Nome da UC.
geometriaa | character varying(4) | 
anocriacao | smallint | Ano de criação.
sigla | character varying(6) | Sigla da UC.
areaha | numeric | Área em hectares.
perimetrom | numeric | Perímetro em metros.
atolegal | character varying(254) | Legislação que criou a UC.
administra | character varying(30) | Esfera de administração (federal, estadual...).
siglagrupo | character varying(2) | 
uf | character varying(9) | Unidades de federação envolvidas.
municipios | character varying(254) | Municípios envolvidos.
biomaibge | character varying(50) | Bioma de acordo com o IBGE.
biomacrl | character varying(100) | 
coordregio | character varying(100) | Coordenação regional.
uorg | smallint | 
geom | geometry(MultiPolygon,4326) | Representação geográfica da UC.

## Tabela: map_ufs

Unidades da Federação.
Campo | Tipo | Descrição
--- | --- | ---
**gid** | integer | Chave primária.
id | double precision | Identificador.
cd_geocodu | character varying(2) | Código.
nome_estado | character varying(50) | Nome.
nome_regiao | character varying(20) | Nome da região.
geom | geometry(MultiPolygonM,4326) | Representação geográfica.
sigla_estado | text | Sigla.
sigla_regiao | text | Sigla da região.

## Tabela: map_world

Mapa completo administrativo do mundo. Fonte: https://gadm.org/download_world.html . Baixada a opção "whole world" em shapefile. Convertida com "shp2pgsql -s 4326 -I gadm36.shp map_world > map_world.sql"
Campo | Tipo | Descrição
--- | --- | ---
**gid** | integer | 
uid | integer | 
gid_0 | character varying(80) | 
id_0 | integer | 
name_0 | character varying(80) | 
gid_1 | character varying(80) | 
id_1 | integer | 
name_1 | character varying(80) | 
varname_1 | character varying(129) | 
nl_name_1 | character varying(87) | 
hasc_1 | character varying(80) | 
cc_1 | character varying(80) | 
type_1 | character varying(80) | 
engtype_1 | character varying(80) | 
validfr_1 | character varying(80) | 
validto_1 | character varying(80) | 
remarks_1 | character varying(97) | 
gid_2 | character varying(80) | 
id_2 | integer | 
name_2 | character varying(80) | 
varname_2 | character varying(116) | 
nl_name_2 | character varying(80) | 
hasc_2 | character varying(80) | 
cc_2 | character varying(80) | 
type_2 | character varying(80) | 
engtype_2 | character varying(80) | 
validfr_2 | character varying(80) | 
validto_2 | character varying(80) | 
remarks_2 | character varying(97) | 
gid_3 | character varying(80) | 
id_3 | integer | 
name_3 | character varying(80) | 
varname_3 | character varying(80) | 
nl_name_3 | character varying(80) | 
hasc_3 | character varying(80) | 
cc_3 | character varying(80) | 
type_3 | character varying(80) | 
engtype_3 | character varying(80) | 
validfr_3 | character varying(80) | 
validto_3 | character varying(80) | 
remarks_3 | character varying(80) | 
gid_4 | character varying(80) | 
id_4 | integer | 
name_4 | character varying(98) | 
varname_4 | character varying(80) | 
cc_4 | character varying(80) | 
type_4 | character varying(80) | 
engtype_4 | character varying(80) | 
validfr_4 | character varying(80) | 
validto_4 | character varying(80) | 
remarks_4 | character varying(80) | 
gid_5 | character varying(80) | 
id_5 | integer | 
name_5 | character varying(80) | 
cc_5 | character varying(80) | 
type_5 | character varying(80) | 
engtype_5 | character varying(80) | 
region | character varying(80) | 
varregion | character varying(80) | 
zone | integer | 
geom | geometry(MultiPolygon,4326) | 

## Tabela: netids

Cadastro de usuário em rede social.
Campo | Tipo | Descrição
--- | --- | ---
**user_id** | integer | Chave do usuário.
**netid** | text | Código do usuário na rede social.
**network** | text | Rede social (facebook, twitter, instagram ou google).

## Tabela: record

Registro de observação.
Campo | Tipo | Descrição
--- | --- | ---
**id** | integer | Chave primária.
record_date | timestamp with time zone | Data do registro.
record_modified | timestamp with time zone | Data de modificação do registro.
user_id | integer | Usuário associado.
**country** | text | País.
**stateprovince** | text | Estado.
**municipality** | text | Município.
locality | text | Localidade.
decimallatitude | text | Latitude em graus decimais.
decimallongitude | text | Longitude em graus decimais.
elevation | text | Elevação em metros.
verbatimeventdate | text | Data/hora original da observação.
eventdate | text | Data da observação (dd/mm/aaaa).
eventtime | text | Hora da observação.
eventremarks | text | Observações.
point | geometry(Point,4326) | Representação geométrica do ponto.
taxgrp | text | Tipo de animal de acordo com as definições em def_expertise (key).
**habit** | text | Hábito da planta de acordo com as definições em def_habit.
**interaction** | text | Tipo de interação de acordo com as definições em def_interaction.
datum | text | Datum das coordenadas.
eventday | integer | Dia da observação.
eventmonth | integer | Mês da observação.
eventyear | integer | Ano da observação.

## Tabela: session

Controle de sessão.
Campo | Tipo | Descrição
--- | --- | ---
**session_id** | text | Chave primária.
user_id | integer | Chave do usuário.
last_seen | timestamp with time zone | Última utilização da sessão.
**network** | text | Local onde foi feito o login (guardioes, google, facebook, twitter ou instagram).

## Tabela: users

Usuários.
Campo | Tipo | Descrição
--- | --- | ---
**id** | integer | Chave primária.
**name** | text | Nome.
nickname | text | Apelido.
email | text | E-mail.
password | text | Senha criptografada.
birthday | integer | Data de aniversário (formato AAAAMMDD).
gender | text | Gênero (male ou female).
picture | text | Nome do arquivo local com a foto do usuário.
language | text | Idioma de preferência (pt ou en).
**education** | education_type | Escolaridade (fundamental, medio, superior ou pos).
since | timestamp with time zone | Data/hora de cadastro no sistema.
flags | text | 
curriculum | text | Link para o currículo.
**category** | category_type | Tipo de usuário (guardiao, especialista, admin ou super).
**status** | status_type | Status do usuario: ativo, pendente, inativo...
comments | text | Comentários associados à inscrição do usuário
agreement | boolean | Usuário aceita ou não os termos de uso dos guardiões
terms_guardiao | timestamp with time zone | Data de aceite dos termos de uso dos guardiões
alert_period | text | Frequência com que o usuário aceita receber notificações (day, week, never).
last_alert | timestamp with time zone | Data/hora de envio da última notificação.
last_seen | timestamp with time zone | Data/hora do último login.
terms_especialista | timestamp with time zone | 
is_super | boolean | Usuário é super usuário do sistema
is_admin | boolean | Usuário é administrador dos guardiões


***************************

# Banco: sp_dic

Banco de dados com dicionário de espécies.

## Tabela: flora2020

Contém nomes científicos válidos de plantas extraídos da Flora do Brasil 2020 (http://ipt.jbrj.gov.br/jbrj/resource?r=lista_especies_flora_brasil)
Campo | Tipo | Descrição
--- | --- | ---
**id** | integer | 
family | text | 
genus | text | 
species | text | 
subspecies | text | 
plain_name | text | 
full_name | text | 
common_name | text | 
plain_common_name | text | 

## Tabela: flora2020_words

Contém nomes científicos válidos de plantas extraídos da Flora do Brasil 2020 (http://ipt.jbrj.gov.br/jbrj/resource?r=lista_especies_flora_brasil)
Campo | Tipo | Descrição
--- | --- | ---
id | integer | 
family | text | 
genus | text | 
species | text | 
subspecies | text | 
plain_name | text | 
full_name | text | 
common_name | text | 
plain_common_name | text | 
word | text | 

## Tabela: moure

Contém nomes científicos válidos de abelhas extraídos do Catálogo de Abelhas Moure (http://moure.cria.org.br/)
Campo | Tipo | Descrição
--- | --- | ---
**id** | integer | 
family | text | 
genus | text | 
species | text | 
subspecies | text | 
plain_name | text | 
full_name | text | 
common_name | text | 
plain_common_name | text | 

## Tabela: moure_words

Contém nomes científicos válidos de abelhas extraídos do Catálogo de Abelhas Moure (http://moure.cria.org.br/)
Campo | Tipo | Descrição
--- | --- | ---
id | integer | 
family | text | 
genus | text | 
species | text | 
subspecies | text | 
plain_name | text | 
full_name | text | 
common_name | text | 
plain_common_name | text | 
word | text | 

## Tabela: sp2000_animalia

Contém nomes científicos válidos do reino Animalia extraídos do Catálogo da Vida (http://www.catalogueoflife.org/DCA_Export/archive.php)
Campo | Tipo | Descrição
--- | --- | ---
**id** | integer | 
family | text | 
genus | text | 
species | text | 
subspecies | text | 
plain_name | text | 
full_name | text | 
common_name | text | 
plain_common_name | text | 

## Tabela: sp2000_animalia_words

Contém nomes científicos válidos do reino Animalia extraídos do Catálogo da Vida (http://www.catalogueoflife.org/DCA_Export/archive.php)
Campo | Tipo | Descrição
--- | --- | ---
id | integer | 
family | text | 
genus | text | 
species | text | 
subspecies | text | 
plain_name | text | 
full_name | text | 
common_name | text | 
plain_common_name | text | 
word | text | 

## Tabela: sp2000_plantae

Contém nomes científicos válidos do reino Plantae extraídos do Catálogo da Vida (http://www.catalogueoflife.org/DCA_Export/archive.php)
Campo | Tipo | Descrição
--- | --- | ---
**id** | integer | 
family | text | 
genus | text | 
species | text | 
subspecies | text | 
plain_name | text | 
full_name | text | 
common_name | text | 
plain_common_name | text | 

## Tabela: sp2000_plantae_words

Contém nomes científicos válidos do reino Plantae extraídos do Catálogo da Vida (http://www.catalogueoflife.org/DCA_Export/archive.php)
Campo | Tipo | Descrição
--- | --- | ---
id | integer | 
family | text | 
genus | text | 
species | text | 
subspecies | text | 
plain_name | text | 
full_name | text | 
common_name | text | 
plain_common_name | text | 
word | text | 


***************************

# Banco: guardioes_api

Banco de dados usado na interação do app com o website.

## Tabela: image


Campo | Tipo | Descrição
--- | --- | ---
**image_id** | text | Chave da imagem.
**record_id** | text | Chave do registro.
date | timestamp with time zone | Data e hora de envio da imagem.
**number** | integer | 
**data** | text | Conteúdo da imagem.
**format** | text | Formato da imagem (ex: jpg).

## Tabela: record

Registro de interação entre espécies enviado pelo app durante sessão
Campo | Tipo | Descrição
--- | --- | ---
**record_id** | text | Chave do registro
**session_id** | text | Chave da sessão
date | timestamp with time zone | Data e hora de envio do registro.
country | text | País.
stateprovince | text | Estado.
municipality | text | Município.
locality | text | Localidade.
decimallatitude | text | Latitude em graus decimais.
decimallongitude | text | Longitude em graus decimais.
elevation | text | Elevação em metros.
verbatimeventdate | text | Data/hora original da observação.
eventdate | text | Data da observação (dd/mm/aaaa).
eventtime | text | Hora da observação.
eventremarks | text | Observações.
taxgrp | text | Tipo de animal de acordo com as definições em def_expertise (key).
habit | text | Hábito da planta de acordo com as definições em def_habit.
interaction | text | Tipo de interação de acordo com as definições em def_interaction.
a_family | text | Família do animal.
a_vernacularname | text | Nome comum do animal.
a_scientificname | text | Nome científico do animal.
a_identificationremarks | text | Observações sobre a identificação do animal.
p_family | text | Família da planta.
p_vernacularname | text | Nome comum da planta.
p_scientificname | text | Nome científico da planta.
p_identificationremarks | text | Observações sobre a identificação da planta.

## Tabela: session

Sessão de interação entre app e website
Campo | Tipo | Descrição
--- | --- | ---
**session_id** | text | Chave da sessão
**user_id** | integer | Chave do usuário
date | timestamp with time zone | Data e hora de início
last_call | timestamp with time zone | Data e hora da última interação


***************************

# Banco: guardioes_log

Banco de dados para armazenamento de logs de acesso. Possui uma estrutura hierárquica com novas tabelas sendo automaticamente criadas ao longo do tempo. A tabela principal, log, é usada como referência para tabelas anuais, nomeadas log_aaaa, e estas por sua vez são utilizadas como referência para tabelas mensais, nomeadas log_aaaamm. 

## Tabela: log

Tabela base para armazenamento de logs de acesso ao website
Campo | Tipo | Descrição
--- | --- | ---
**id** | bigint | Chave do registro.
**date** | timestamp | Data e hora do acesso.
**user_id** | integer | Chave do usuário.
**action** | text | Script acessado.
**detail** | text | Parâmetros.

