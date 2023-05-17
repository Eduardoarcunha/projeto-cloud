## Conexão do RDS da AWS com uma interface gráfica de base de dados
**Projeto de Computação em Nuvem**
**Aluno:** Eduardo Araujo Rodrigues da Cunha
**Data:** 26/05/2023

#### Sobre a implementação

Este roteiro tem como objetivo conectar uma interface gráfica de banco de dados, por exemplo o MySQL Workbench, com um banco de dados RDS que é um serviço da amazon de banco de dados relacionais. 
A infraestrutura consiste em uma EC2 atuando como JumpBox para a base RDS, isso possibilita no futuro, configurações de conexões mais seguras, uma vez que não é possível conectar-se diretamente a base de dados.

#### Pré-requisitos da implementação

**1.** Conta [AWS](https://aws.amazon.com/pt/) e credenciais para instalação da infraestrutura.


**2.** [Terraform](https://www.terraform.io/) instalado em sua máquina, essa é uma ferramenta de software de infraestrutura como código (IaC).

**3.** *Keypair* com o nome ***mykp*** na pasta key-pair, pode ser gerada pelo seguinte comando:

**4.** MySQL Client instalado para testarmos a conexão com a base.

```
ssh-keygen -t rsa -b 4096
```

**Observação:** (Caso queira testar a conexão pelo MySqlWorkbench) [este](https://www.mysql.com/products/workbench/) deve estar instalado em sua máquina.

#### Estrutura do projeto

O projeto foi divido nos seguintes arquivos:

***roteiro&period;md:*** Arquivo detalhando melhor a implementação e explicando passo a passo do código.

***provider&period;tf:*** Arquivo terraform onde informa-se as credenciais da AWS, e onde é informado qual nosso provider.

***instances&period;tf:*** Declaração da nossa instância EC2 que atua como Jump Box.

***network&period;tf:*** Declaração dos recursos relacionados a rede.

***rds&period;tf:*** Declaração do recurso referente a base de dados RDS.

***security-groups&period;tf:*** Declaração e configuração dos security groups de cada rede.

***outputs&period;tf:*** Saídas do terraform.

***security-groups&period;tf:*** Variáveis para a implementação.


#### Como utilizar a infraestrutura?

**IMPORTANTE:** Primeiro devemos configurar nossa variáveis de ambiente que não podem ser vazadas! Como nosso usuário master de nosso banco de dados RDS.

Com o código em um diretório de seu computador, e com os pré-requisitos atendidos, primeiramente roda-se o seguinte comando:

```
terraform init
```

Feito isso, o terraform estará corretamente inicializado no diretório, e podemos então subir a infraestrutura:

```
terraform apply -var-file="secrets.tfvars"
```

Pronto! Agora para testar a conexão, primeiramente utilizaremos a JumpBox como túnel para nossa base de dados:

```
ssh -i mykp -f -N -L 5000:<RDS_ENDPOINT>:3306 <EC2_USER>@<PUBLIC_IP> -v
```

Feito o túnel, agora é nos conectar a base de dados, podemos fazer isso por outra janela do terminal e usando o MySql:
```
mysql -u <DB User> -h 127.0.0.1 -P 5000 -p
```

Finalizado! Para garantirmos que a base está funcionando, podemos rodar o seguinte comando nesse mesmo terminal:
```
show DATABASES;
```