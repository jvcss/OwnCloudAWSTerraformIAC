
# Automatizando publicação do OwnCloud com AWS e Terraform

<ol>
<li>Criar conta na AWS</li>
<img src="./passo_a_passo/criar_conta_aws.png"></img>
<p>Preencha suas informações e escolha o tipo de conta que preferir</p>
<img src="./passo_a_passo/criar_conta_aws_tipo_conta.png"></img>
<p>Instale o CLI da AWS e faça uso do IAM na sua conta que você criou acima</p>
<img src="./passo_a_passo/aws_instalar_cli.png"></img>
<p>O IAM (Identity and Access Management) é uma forma de controlar seu acesso de forma granular, nós acessamos a página do IAM no console da AWS.</p>
<img src="./passo_a_passo/iam_aws_pagina.png"></img>
<p>Vamos em Users para criar um novo usuario que o Terraform terá acesso</p>
<img src="./passo_a_passo/criar_usuario_iam.png"></img>
<p>A discussão sobre grupos de acesso e políticas de acesso é extremamente complexa e longa, vamos nos ater a criar um novo grupo dando acesso apenas aos recursos EC2 fundamentais como mostra a imagem </p>
<img src="./passo_a_passo/criar_usuario_iam_2.png"></img>
<img src="./passo_a_passo/grupo_acesso_iam.png"></img>
<p>Uma vez criado o usuario IAM, atribua uma chave para ele, e com essa chave que vamos acessar via CLI a AWS. Clicando no nome do user criado você verá o sumário e abas abaixo sendo uma delas Security Credentials</p>
<img src="./passo_a_passo/criar_usuario_iam_3_chave.png"></img>
<p>Na tela de criar a cahve escolha o Use Case para CLI, dê uma descrição e baixe o arquivo csv com os dados Access key,
Secret access key</p>
<p>Abra um terminal e digite <code>aws configure</code> preencha corretamente com a regiao de acesso que você quer dar para esse user bem como a chave e secret. Pronto você configurou o acesso da sua CLI AWS.</p>
<img src="./passo_a_passo/criar_usuario_iam_4_chave_na_cli.png"></img>
<li>Baixar e Instalar o Terraform</li>
<img src="./passo_a_passo/baixar_terraform.png"></img>
<p>Escolha a versão correta para seu O.S, no meu caso Win32</p>
<img src="./passo_a_passo/baixar_terraform_windows_x64.png"></img>
<p>Após extrair o executável. Adicione ao Path</p>
<img src="./passo_a_passo/adicionar_terraform_ao_path.png"></img>
<p>Use a extensão oficial do Terraform no VSCode.</p>
<img src="./passo_a_passo/baixar_extensao_terraform.png"></img>
<li>Crie a Infraestrutura como Código em uma pasta</li>
<img src="./passo_a_passo/IaC_terraform.png"></img>
<i>o código acima criado por JVCSS é público no <a href="https://github.com/jvcss/OwnCloudAWSTerraformIAC">Repositório</a></i></br>
<b>deixe sua estrela!</b>
<p>Nessa Infraestrutura de Instância EC2 estamos criando uma EC2 na região SP do brasil, especificamente definindo uma zona para ter acesso ao DNS gerado automaticamente.</p>
<p>Estamos permitindo acesso irrestrito via SSH uma prática não recomendada! O motivo é para facilitar acesso remoto via diferentes máquinas.</p>
<p>Estamos configurando a Networking para dar acesso a internet para essa instância. bem como permitir acesso entre instâncias na mesma VPC</p>
<p>Por fim, estamos automatizando a entrega do SaaS com o docker com o orquestrador compose. </p>
<p>Usamos o NGINX como framework de controle proxy porque ele permite granularidade na entrega bem como controles finos como cache e filtros contra ataques de injeção de conteúdo arbitrário ou DDOS.</p>
<p>O SaaS OwnCloud depende do MariaDB e do Redis, por isso criamos também as instancias locais desses serviços (note que em uma aplicação real esses serviços são na verdade separados do EC2 com os nomes de RDS[Relational Database Service] e ElastiCache na AWS respectivamente)</p>
<p>Um detalhe importante é como nós elegantemente controlamos a quantidade de memória RAM e CPU permitida para o SaaS via orquestrador docker-compose</p>
<img src="./passo_a_passo//docker_compose_controle_saas.png"></img>
<p>Porque via teste notamos que o uso de recursos desse SaaS superou e muito o limite da nossa Instância com os limites gratuitos, inutilizando-a.</p>
<p>A finalização então está na entrega ao público via NGINX com seu arquivo de configuração, nessa versão simplificada permitimos apenas conexão HTTP. Já que um certificado auto-assinado não tem valor comercial não foi aplicado nesse exemplo.</p>
<img src="./passo_a_passo/nginx_arquivo_config.png"></img>
<i>Nesse arquivo nginx.conf estamos usando o Framework como proxy como mostra a primeira linha do arquivo.</i>
<p>As definições nesse arquivo estão em resumo definindo limites, como quantidade de nós criados, tempo de validade de cache, tipos de conexão aceita, tipos de arquivo, tamanho de encriptação, local onde salvar logs de acesso, encaminhamento de cabeçalho e o mais importante o URI do serviço a ser encaminhado que nesse caso com o docker é o nome do container definido no arquivo docker-compose.yaml</p>
<p>Então após definir todo nosso ambiente, realizar as devidas automações como substuição das constantes OWNCLOUD_DOMAIN e OWNCLOUD_TRUSTED_DOMAINS para o IP Publico e DNS publico dessa Instância via arquivo Terraform.</p>
<p>Nós podemos apenas com simples comandos <code>terraform init</code>  <code>terraform validade</code> <code>terraform plan -out planoNovo</code> concluir a configuração dessa Infraestrutura e enviar para a AWS com <code>terraform apply "planoNovo"</code></p>
<p>Finalmente após toda essa configuração podemos garantir que criamos o ambiente IaC consistente.</p>
<p>Acesse seu OwnCloud via DNS: lembre-se de tirar o S do HTTP, o chrome automaticamente troca o protocolo mas você pode acessar manualmente apenas apagando o S. Em alguns casos é necessário acessar seu site HTTP via Aba Anônina.</p>
<p>Segue o print da publicação onde: Criamos uma EC2 nova, clonamos o repositório e ligamos os serviços.</p>
<img src="./passo_a_passo/automatizado.png"></img>
<img src="./passo_a_passo/automatizado_aws_view.png"></img>
<img src="./passo_a_passo/automatizado_owncloud.png"></img>
<i>user: vide Container OwnCloud no Docker-Compose<i>
<i>senha: vide Container OwnCloud no Docker-Compose<i>
</ol>
