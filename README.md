## Conexão do RDS da AWS com uma interface gráfica de base de dados
**Projeto de Computação em Nuvem**
**Aluno:** Eduardo Araujo Rodrigues da Cunha
**Data:** 26/05/2023

### Sobre a implementação

Este roteiro tem como objetivo conectar uma interface gráfica de banco de dados, por exemplo o MySQL Workbench, com um banco de dados RDS que é um serviço da amazon de banco de dados relacionais. 
A infraestrutura consiste em uma EC2 atuando como JumpBox para a base RDS, isso possibilita no futuro, configurações de conexões mais seguras, uma vez que não é possível conectar-se diretamente a base de dados.

### Pré-requisitos da implementação

**1.** Conta [AWS](https://aws.amazon.com/pt/) e credenciais para instalação da infraestrutura.


**2.** [Terraform](https://www.terraform.io/) instalado em sua máquina, essa é uma ferramenta de software de infraestrutura como código (IaC).

**3.** *Keypair* com o nome ***mykp*** no diretório do projeto, pode ser gerada pelo seguinte comando:

```
ssh-keygen -t rsa -b 4096
```
**Importante:** Se o nome da sua chave for diferente deste, você precisará mudar a referência no código terraform, além de que o .gitignore provavelmente não irá evitar que essa chave seja *commitada*.


**4.** MySQL Client instalado para testarmos a conexão com a base. [Tutorial Windows](https://www.youtube.com/watch?v=nfDyFWIDWoQ) / [Tutorial Linux](https://dev.mysql.com/doc/mysql-shell/8.0/en/mysql-shell-install-linux-quick.html)



**Observação:** (Caso queira testar a conexão pelo MySQLWorkbench) [este](https://www.mysql.com/products/workbench/) deve estar instalado em sua máquina.


### Guia rápido de uso (guia detalhado após essa sessão)

Aqui está um rápido guia de uso da infraestrutura, após essa sessão, tem-se a documentação mais detalhada de cada parte do código.

**IMPORTANTE:** Primeiro devemos configurar nossa variáveis de ambiente que não podem ser vazadas! Como nosso usuário master de nosso banco de dados RDS.

Com o código em um diretório de seu computador, e com os pré-requisitos atendidos, primeiramente roda-se o seguinte comando:

```
terraform init
```

Feito isso, o terraform estará corretamente inicializado no diretório, e podemos então subir a infraestrutura:

```
terraform apply
```

Pronto! Agora para testar a conexão, primeiramente utilizaremos a JumpBox como túnel para nossa base de dados:

```
ssh -i mykp -f -N -L 5000:<RDS_ENDPOINT>:3306 <EC2_USER>@<PUBLIC_IP> -v
```

Feito o túnel, agora nos conectamos a base de dados, podemos fazer isso por outra janela do terminal e usando o MySQL:
```
mysql -u <DB User> -h 127.0.0.1 -P 5000 -p
```

Finalizado! Para garantirmos que a base está funcionando, podemos rodar o seguinte comando nesse mesmo terminal:
```
show DATABASES;
```
### Roteiro detalhado

#### Subdivisão dos arquivos:

***roteiro&period;md:*** Arquivo detalhando melhor a implementação e explicando passo a passo do código.

***provider&period;tf:*** Arquivo terraform onde informa-se as credenciais da AWS, e onde é informado qual nosso provider.

***instances&period;tf:*** Declaração da nossa instância EC2 que atua como Jump Box.

***network&period;tf:*** Declaração dos recursos relacionados a rede.

***rds&period;tf:*** Declaração do recurso referente a base de dados RDS.

***security-groups&period;tf:*** Declaração e configuração dos security groups de cada rede.

***outputs&period;tf:*** Saídas do terraform.

***security-groups&period;tf:*** Variáveis para a implementação.

#### Implementação passo a passo

**1. Preparação do ambiente**

Antes de iniciarmos a implementação da infraestrutura em si, devemos preparar nosso ambiente de trabalho, para isso, basta criarmos uma pasta projeto e um arquivo ***provider&period;tf***.

Neste arquivo, primeiramente iremos referenciar qual o nosso provider, além de passarmos nossas credenciais da AWS.

Aqui também criaremos um bloco de dados para conseguirmos encontrar facilmente quais as zonas disponíveis da AWS para nossa região definida no provider (*us-east-1*).

**Observação:** 
*Não coloque diretamente suas credencias no código, existem maneiras melhores de referenciá-las no arquivo, como usando variáveis de ambiente. Em nosso caso, estamos usando os arquivos de configuração do AWS CLI como referência, e evitando a exposição de nossas credenciais. Se quiser ver como configurar esses arquivos, confira [este tutorial da Amazon](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html).*

``` tf
provider "aws" {
  region = "us-east-1"

  # Linux (Path genérico do AWS CLI)
  shared_config_files      = ["$HOME/.aws/config"]
  shared_credentials_files = ["$HOME/.aws/credentials"]

  # Windows (MUDE O CAMINHO PARA SEU USUARIO)
  # shared_config_files      = ["C:/Users/eduar/.aws/config"]
  # shared_credentials_files = ["C:/Users/eduar/.aws/credentials"]
}

data "aws_availability_zones" "available" {
  state = "available"
}
```

Antes de continuarmos, no terminal chegue até o diretório de trabalho e rode o seguinte comando:
```
terraform init
```

Após o comando, alguns arquivos serão criados no diretório, não precisamos nos preocupar com eles, para saber se a inicialização deu certo, a seguinte mensagem deve aparecer em seu terminal:

![Init terraform](/imgs/init-terraform.png)

Depois disso, iremos criar o arquivo ***variables&period;tf***, nele estará declarado os CIDR de nossas subredes privadas.

Agora, vamos criar um arquivo ***network&period;tf*** o aqui, criaremos nossa rede virtual (VPC) e também um gateway para ela:

```
# Creating VPC
resource "aws_vpc" "rds_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "rds_vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "rds_igw" {
  vpc_id = aws_vpc.rds_vpc.id

  tags = {
    Name = "rds_igw"
  }
}
```

Feito isso, partimos para a criação de uma subrede pública, e duas privadas, suas tabelas de roteamento e também um grupo de subredes para nosso RDS.

**Observação:** É necessário a criação de duas redes privadas pois para atrelarmos um grupo de subredes ao RDS esse grupo necessita de pelo menos duas subredes.

```
# Public subnet
resource "aws_subnet" "rds_subnet_public" {
  vpc_id            = aws_vpc.rds_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "rds_subnet_public"
  }
}

# Private subnet
resource "aws_subnet" "rds_subnet_private" {
  count = 2
  vpc_id            = aws_vpc.rds_vpc.id
  cidr_block        = var.private_subnets_cidr_blocks[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "rds_subnet_private"
  }
}

# Public route table
resource "aws_route_table" "rds_route_public_table" {
  vpc_id = aws_vpc.rds_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.rds_igw.id
  }

  tags = {
    Name = "rds_route_public_table"
  }
}

resource "aws_route_table_association" "rds_route_public_table_association" {
  subnet_id      = aws_subnet.rds_subnet_public.id
  route_table_id = aws_route_table.rds_route_public_table.id
}

# Private route table
resource "aws_route_table" "rds_route_private_table" {
  vpc_id = aws_vpc.rds_vpc.id

  tags = {
    Name = "rds_route_private_table"
  }
}

resource "aws_route_table_association" "rds_route_private_table_association" {
  subnet_id      = aws_subnet.rds_subnet_private[1].id
  route_table_id = aws_route_table.rds_route_private_table.id
}


# RDS subnet group
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds_subnet_group"
  subnet_ids = [for subnet in aws_subnet.rds_subnet_private : subnet.id]
}
```

Agora, criaremos os grupos de segurança para nossa EC2 e para nosso banco de dados, a instância EC2 deve ser acessível por *HTTPS*, *HTTP* e *SSH*, enquanto a base RDS só pode ser acessível pela instância EC2, faremos tudo isso em um novo arquivo ***security-groups&period;tf***:

**Observação:** Como neste exemplo estamos trabalhando com um banco de dados SQL, a porta do serviço é 3306, mas esse valor pode mudar.

```
# EC2 security group
resource "aws_security_group" "rds_ec2_sg" {
  name        = "rds_ec2_sg"
  description = "Allow traffic to EC2"

  vpc_id = aws_vpc.rds_vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds_ec2_sg"
  }
}

# RDS security group
resource "aws_security_group" "rds_db_sg" {
  name        = "rds_db_sg"
  description = "Allow traffic to RDS"

  vpc_id = aws_vpc.rds_vpc.id

  ingress {
    description = "MySQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.rds_ec2_sg.id]
  }

  tags = {
    Name = "rds_db_sg"
  }
}
```

Depois disso, deve-se criar o grupo de subredes para nosso banco de dados, além do próprio banco de dados. Aqui estão definidas as configurações gerais desse, como seu armazenamento.

Agora, podemos criar nosso banco de dados RDS e definir suas configurações gerais, vamos fazer isso no arquivo ***rds&period;tf*** 

**Importante:** Note que é aqui que estamos definindo o usuário e a senha de nosso banco de dados, lembre-se de guardar esses valores para nos conectarmos na base no futuro.

```
# RDS instance
resource "aws_db_instance" "rds_instance" {
  allocated_storage    = 20
  engine               = "mysql"
  instance_class       = "db.t2.micro"
  db_name              = "rds_db"
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.id
  username             = "admin"
  password             = "admineduardo"
  vpc_security_group_ids = [aws_security_group.rds_db_sg.id]
  skip_final_snapshot = true

  tags = {
    Name = "rds_instance"
  }
}
```

Agora, precisamos criar um par de chaves para nossa instância EC2, uma forma de criá-las é pelo próprio terminal:

**Importante:** Atenção para qual nome escolher para as chaves, pois você precisa referenciar o arquivo delas corretamente no código! No tutorial estamos utilizando o nome ***mykp***

```
ssh-keygen -t rsa -b 4096
```

Ao rodar o comando, escolha um nome para os arquivos em que serão salvas suas chaves, neste momento, seu projeto deve estar da seguinte maneira:

![Estrutura projeto](/imgs/estrutura-projeto.png)


Feito isso, agora devemos criar nossa instância EC2, referenciar nossa chave privada (o arquivo com extensão *.pub*), além de criar um Elastic IP para nossa instância. Isso será feito no arquivo ***instances&period;tf*** :

**Cuidado:** Se atente em como você está referenciando sua chave em *public_key*

```
# Key pair
resource "aws_key_pair" "rds_ec2_key_pair" {
  key_name = "rds_kp"
  public_key = file("./key-pair/mykp.pub")
}

# EC2 instance
resource "aws_instance" "ec2_instance" {
  ami           = "ami-007855ac798b5175e"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.rds_ec2_key_pair.key_name
  subnet_id     = aws_subnet.rds_subnet_public.id
  vpc_security_group_ids = [aws_security_group.rds_ec2_sg.id]

  tags = {
    Name = "ec2_instance"
  }
}

# Elastic IP
resource "aws_eip" "rds_eip" {
  vpc = true
  instance = aws_instance.ec2_instance.id

  tags = {
    Name = "rds_eip"
  }
}
```

Finalmente, agora adicionaremos algumas saídas em nosso código, faremos isso no arquivo ***outputs&period;tf***, para podermos ver os endereços que serão necessários na conexão com a nossa base de dados:

```
# Public IP (Elastic IP)
output "public_ip" {
  value = aws_eip.rds_eip.public_ip
}

# Endpoint (Database endpoint)
output "endpoint" {
  value = aws_db_instance.rds_instance.address
}

# Port
output "port" {
  value = aws_db_instance.rds_instance.port
}
```

Feito tudo isso, basta rodar o comando abaixo e digitar *yes*:
```
terraform apply
```

No terminal, deve ter aparecido algo como isto (a instalação da infraestrutura vai demorar em torno de 5 minutos):

![Print terminal](/imgs/apply-feito.png)

Guarde esse valores! Com eles nós iremos fazer nossa conexão com a base de dados!

#### Realizando a conexão diretamente por CLI

Uma maneira de testarmos nossa conexão é fazer ssh para nossa EC2, e então nos conectarmos a base, para isso, basta rodar o seguinte comando no terminal para criar o túnel:

```
ssh -i mykp -f -N -L 5000:<RDS_ENDPOINT>:3306 <EC2_USER>@<PUBLIC_IP> -v
```

Agora, já é possível nos conectar com a base de dados! Em outro terminal, rode o seguinte comando substituindo *DB User* pelo usuario de sua base de dados! Após rodar o comando, a senha da base será requisitada, basta inseri-la que estaremos conectados!

```
mysql -u <DB User> -h 127.0.0.1 -P 5000 -p
```

Para verificarmos se tudo esta funcionando corretamente, basta rodar o seguinte comando:

```
show DATABASES;
```



#### Realizando a conexão pelo MySQL

Agora, podemos finalmente realizar nossa conexão pelo MySQLWorkbench, ambiente mais propício para trabalhar com a base do que o terminal! 

Conseguimos realizar a conexão pela própria ferramenta!

Ta tela inicial do MySql, iremos clicar no **+** e adicionar uma nova conexão.

![Print terminal](/imgs/mysql-telainicial.png)

Então, uma janela vai aparecer para configurarmos ela, o primeiro passo é mudar o *Connection Method* para *Standard TCP/IP over SSH*.

Aqui devemos fazer as seguintes mudanças **usando os valores dos outputs**:

**SSH Hostname:** Esse é o **public_ip** de nossa EC2.

**SSH Username:** É o usuario da nossa EC2, por padrão, é **ubuntu**

**SSH Key File:** Aqui devemos referenciar nosso arquivo de chaves criado anteriormente (**Importante:** referencie a chave privada e não a pública!)

**MySQL Hostname:** É o **endpoint** dos nossos outputs!

**MySQL Server Port:** Porta usada para acessar o servidor, por padrão deve ser 3306.

**Username:** É o *username* escolhido na criação de nossa base RDS, no meu caso, é **admin**.

**Password:** É o *password* escolhido na criação de nossa base RDS, no meu caso, é **admineduardo**, para inseri-la, basta clicar em *Store in Vault..* .

Concluindo, sua janela deve estar de forma semelhante a esta:

![Criando conexão](/imgs/mysql-connection.png)


Por fim, basta clicar *Test Connection*, talvez apareça um warning, mas basta confiar na conexão, e então uma mensagem de sucesso irá aparecer na tela, feito isso basta clicar *Ok* e a sua conexão irá aparecer no seu dashboard:


![Conexão criada](/imgs/mysql-final.png)

Feito! Agora você já consegue acessar sua base de dados! Basta clicar na conexão criada:

![Conexão realizada](/imgs/mysql-base.png)

Terminamos! Aqui finalizamos nosso roteiro de implementação, se quiser destruir os recursos criados na AWS basta rodar o seguinte comando:

```
terraform destroy
```

#### Referências

https://medium.com/strategio/using-terraform-to-create-aws-vpc-ec2-and-rds-instances-c7f3aa416133

https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/tutorial-connect-ec2-instance-to-rds-database.html 

https://beabetterdev.com/2022/12/13/how-to-connect-to-an-rds-or-aurora-database-in-a-private-subnet/ 