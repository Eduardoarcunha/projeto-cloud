# Conexão do RDS da AWS com uma interface gráfica de base de dados
**Projeto de Computação em Nuvem**

**Aluno:** Eduardo Araujo Rodrigues da Cunha

**Data:** 26/05/2023

## Sobre a implementação

Este roteiro tem como objetivo conectar uma interface gráfica de banco de dados, por exemplo o MySQL Workbench, com um banco de dados [RDS](https://aws.amazon.com/pt/rds/) que é um serviço da amazon de banco de dados relacionais. 

![](imgs/diagrama.png)

A infraestrutura consiste em uma EC2 atuando como JumpBox para a base RDS, isso possibilita no futuro, configurações de conexões mais seguras, uma vez que não é possível conectar-se diretamente a base de dados.

Porém, o diferencial é que a conexão com a EC2 ocorrerá por meio da AWS Systems Manager Session Manager (SSM), que é uma ferramenta de conexão mais segura, e que dentre várias vantagens que a ferramenta oferece, uma delas é que não é necessário um *key-pair* para nos conectarmos a uma instância EC2.

## Pré-requisitos da implementação

**1.** Conta [AWS](https://aws.amazon.com/pt/) e credenciais para instalação da infraestrutura.

**2.** [Terraform](https://www.terraform.io/) instalado em sua máquina, que é uma ferramenta de software de infraestrutura como código (IaC).

**3.** Para realizarmos a conexão SSM, é **necessário** instalar o AWS CLI e também o plugin do Session Manager! Aqui os links dos tutoriais da Amazon para a instalação do [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) e do plugin do [Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html).

**4.** Para testarmos nossa conexão com a base, temos diferentes opções, neste tutorial 3 são englobadas, para cada uma é necessário um pré-requisito diferente, escolha a que atender melhor sua necessidade:

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**a. Terminal e MySQL Client:** Para nos conectarmos pelo terminal, é necessário ter o MySQL Client instalado, aqui estão os tutoriais para o [Windows](https://www.youtube.com/watch?v=nfDyFWIDWoQ&t=435s) e [Linux](https://phoenixnap.com/kb/install-mysql-ubuntu-20-04).

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**b. Python:** Temos no repositório, um arquivo *notebook* que testa a conexão para a base, para este teste, é necessário, além do python, o seguinte pacote:

``` 
pip install mysql-connector-python
```

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**c. MySQL Workbench:** Por fim, também mostraremos como usar a interface gráfica MySQL Workbench para se conectar a base, portanto, é necessário [instalá-la](https://www.mysql.com/products/workbench/).


## Guia rápido de uso (guia detalhado após essa sessão)

Para fins de praticidaded, aqui está um rápido guia de uso da infraestrutura, após essa sessão, tem-se a documentação mais detalhada de cada parte do código. Neste guia rápido, estamos testando a conexão pela maneira **a** (Terminal e MySQL Client)

Clone o código em um diretório de seu computador, e com os pré-requisitos atendidos, vamos inicializar um projeto terraform:

```
terraform init
```

Feito isso, o terraform estará corretamente inicializado no diretório, e podemos subir a infraestrutura, ao rodar o próximo comando, será perguntado se você quer confirmar as mudanças, basta digitar ***yes*** (o processo de instalação pode demorar entre 5 a 8 minutos!):

<span style="color:red"><span style="font-weight:700">IMPORTANTE:</span> Você talvez precisa colocar suas chaves da AWS se estiver no Windows, para isso, basta abrir o arquivo *main&period;tf* e configurar o caminho até o arquivo *.aws* em seu computador. No Linux, simplesmente configurar o AWS CLI deve ser o suficiente para conectar-se a sua conta AWS.

```
terraform apply
```

Pronto! Feito isso, algumas variáveis devem ter aparecido em seu terminal, precisaremos delas! Agora para testar a conexão por meio do AWS SSM:
  
<span style="color:red"><span style="font-weight:700">IMPORTANTE:</span> Troque as variáveis pelos respectivos valores que aparecerem em seu terminal!</span>

```
aws ssm start-session --region us-east-1 --target <INSTANCE_ID> --document-name AWS-StartPortForwardingSessionToRemoteHost --parameters host="<RDS_ENDPOINT>",portNumber="3306",localPortNumber="8001"
```

Feito a conexão, é possível conectar-se a base de dados! Antes, para você saber essas são as credenciais para esse banco de dados (se quiser mudá-las, basta modificar esses valores no arquivo *rds&period;tf*, destruir a infraestrutura e subi-la novamente):

**User:** admin 
**Password:** adminrds

Abra um **novo** terminal e faça a conexão:

<span style="color:red"><span style="font-weight:700">IMPORTANTE:</span> Após digitar o sinal, será solicitado a senha da base de dados!</span>
```
mysql -u <DB_USER> -h 127.0.0.1 -P 8001 -p
```

Finalizado! Para garantirmos que a base está funcionando, podemos rodar o seguinte comando nesse mesmo terminal:
```
show DATABASES;
```

A seguinte imagem deve aparecer:

![](/imgs/databases-terminal.png)

## Roteiro detalhado

Esta secção cobre cada arquivo de nossa infraestrutura, detalhando um pouco mais o que estamos fazendo em cada um.

### Subdivisão dos arquivos:

Antes de explicar cada um dos arquivos terraform, aqui está a estrutura do projeto:

***README&period;md:*** Arquivo detalhando melhor a implementação e explicando passo a passo do código.

***main&period;tf:*** Arquivo principal do terraform onde informa-se as credenciais da AWS, e onde é informado qual nosso provider.

***instances&period;tf:*** Declaração da nossa instância EC2 que atua como Jump Box para a base RDS, além de suas configurações e permissões dentro da rede.

***network&period;tf:*** Declaração dos recursos relacionados a rede.

***rds&period;tf:*** Declaração do recurso referente a base de dados RDS.

***security-groups&period;tf:*** Declaração e configuração dos security groups de cada rede.

***outputs&period;tf:*** Saídas do terraform.

***security-groups&period;tf:*** Variáveis para a implementação da infraestrutura.

***pokemon-rds&period;ipynb:*** Arquivo *notebook* para teste da conexão da infraestrutura.

### Implementação passo a passo

**1. Preparação do ambiente**

Antes de iniciarmos a implementação da infraestrutura em si, devemos preparar nosso ambiente de trabalho, para isso, basta criarmos uma pasta projeto e um arquivo ***main&period;tf***.

Neste arquivo, primeiramente iremos referenciar qual o nosso provider, além de passarmos nossas credenciais da AWS.

**Observação:** 
*Não coloque diretamente suas credencias no código, existem maneiras melhores de referenciá-las no arquivo, como usando variáveis de ambiente. Em nosso caso, para o Windows, referenciando os arquivos de configuração do AWS CLI, e evitando a exposição de nossas credenciais, para o Linux, apenas configurar o AWS CLI deve funcionar. Se quiser ver como configurar esses arquivos dessa maneira, confira [este tutorial da Amazon](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html).*

``` terraform
provider "aws" {
  region = "${var.region}"

  # Windows
  shared_config_files      = ["C:/Users/eduar/.aws/config"]
  shared_credentials_files = ["C:/Users/eduar/.aws/credentials"]
}
```

Antes de continuarmos vamos inicializar nosso projeto terraform, no terminal chegue até o diretório de trabalho e rode o seguinte comando:
```
terraform init
```

Após o comando, alguns arquivos serão criados no diretório, não precisamos nos preocupar com eles, para saber se a inicialização deu certo, a seguinte mensagem deve aparecer em seu terminal:

![Init terraform](/imgs/init-terraform.png)

**2. Variables**

Depois disso, iremos criar o arquivo ***variables&period;tf***, aqui temos dois *data blocks* que requisitam informação da AWS sobre quais regiões estão disponíveis dentro de nossa principal região, além de requisitar também um AMI (Amazon Machine Image) para configurarmos nossa instância EC2.

Também temos as variáveis referentes ao CIDR de nossas subredes privadas e à região dos nossos recursos AWS.

``` terraform
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux_2_ssm" {
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}

variable "region" {
  type        = string
  description = "Region for the resource deployment"
  default     = "us-east-1"
}

variable "private_subnets_cidr_blocks" {
  type = list(string)
  default = [
    "10.0.101.0/24",
    "10.0.102.0/24"
  ]
}

```


**3. Network**

Agora, vamos criar um arquivo ***network&period;tf***, criaremos nossa rede virtual (VPC), as subredes necessárias e gateways necessários, além do grupo de subredes de nossa base de dados!

**Observação:** É necessário a criação de duas redes privadas pois para atrelarmos um grupo de subredes ao RDS esse grupo necessita de pelo menos duas subredes.

``` terraform
# Create a VPC
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "vpc-${var.region}"
  }
}

# Create an internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "igw-${var.region}"
  }
}

# Create a public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.region}a"
  tags = {
    Name = "Public Subnet"
  }
}

# Create a private subnet
resource "aws_subnet" "private_subnet" {
  count = 2
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_subnets_cidr_blocks[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "rds_subnet_private"
  }
}

# Create a NAT gateway
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id
  tags = {
    Name = "ngw-${var.region}"
  }
}

# Create an EIP for the NAT gateway
resource "aws_eip" "nat_eip" {
  vpc = true
}

# Create a public route table and associate it with the public subnet
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "Public route table"
  }
}

resource "aws_route_table_association" "public_route_table_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# Create a private route table and associate it with the private subnet
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
  tags = {
    Name = "Private route table"
  }
  
}

resource "aws_route_table_association" "private_route_table_association" {
  count = 2
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_route_table.id
}

#RDS subnet group
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds_subnet_group"
  subnet_ids = [for subnet in aws_subnet.private_subnet : subnet.id]
}
```

**4. Security Groups**

Agora, criaremos os grupos de segurança para nossa EC2 e para os endpoints de nossa rede, que possibilitam a conexão a recursos privados sem o uso de uma conexão pública! Faremos tudo isso em um novo arquivo ***security-groups&period;tf***:

**Observação:** Como neste exemplo estamos trabalhando com um banco de dados SQL, a porta do serviço é 3306, mas esse valor pode mudar de acordo com sua escolha.

``` terraform
# Create a security group for the EC2 instance
resource "aws_security_group" "instance_security_group" {
  name_prefix = "instance-sg"
  vpc_id      = aws_vpc.vpc.id
  description = "security group for the EC2 instance"

  # Outbound rules (HTTP, MYSQL)
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS outbound traffic"    
  }

  egress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow MYSQL outbound traffic"
  }

  # Inbound rules (MYSQL)
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow MYSQL traffic from VPC"
  }

  tags = {
    Name = "EC2 Instance security group"
  }
}


# Security group for VPC Endpoints
resource "aws_security_group" "vpc_endpoint_security_group" {
  name_prefix = "vpc-endpoint-sg"
  vpc_id      = aws_vpc.vpc.id
  description = "security group for VPC Endpoints"

  # Allow inbound HTTPS traffic
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
    description = "Allow HTTPS traffic from VPC"
  }

  tags = {
    Name = "VPC Endpoint security group"
  }
}

locals {
  endpoints = {
    "endpoint-ssm" = {
      name = "ssm"
    },
    "endpoint-ssmm-essages" = {
      name = "ssmmessages"
    },
    "endpoint-ec2-messages" = {
      name = "ec2messages"
    }
  }
}

resource "aws_vpc_endpoint" "endpoints" {
  vpc_id            = aws_vpc.vpc.id
  for_each          = local.endpoints
  vpc_endpoint_type = "Interface"
  service_name      = "com.amazonaws.us-east-1.${each.value.name}"
  # Add a security group to the VPC endpoint
  security_group_ids = [aws_security_group.vpc_endpoint_security_group.id]
}
```

**5. Instância RDS**

Depois disso, podemos criar nosso banco de dados RDS e definir suas configurações gerais, vamos fazer isso no arquivo ***rds&period;tf*** .

**Importante:** Note que é aqui que estamos definindo o usuário e a senha de nosso banco de dados, lembre-se de guardar esses valores para nos conectarmos na base no futuro.

``` terraform
# RDS instance
resource "aws_db_instance" "rds_instance" {
  allocated_storage    = 20
  engine               = "mysql"
  instance_class       = "db.t2.micro"
  db_name              = "rds_db"
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.id
  username             = "admin"
  password             = "adminrds"
  vpc_security_group_ids = [aws_security_group.instance_security_group.id]
  skip_final_snapshot = true

  tags = {
    Name = "rds_instance"
  }
}
```

**6. Instância EC2**

Feito isso, agora devemos criar nossa instância EC2, além de atrelar a ela um *IAM role*, que define quais permissões essa instância tem em nossa rede. Isso será feito no arquivo ***instances&period;tf*** :


``` terraform
# Create IAM role for EC2 instance
resource "aws_iam_role" "ec2_role" {
  name = "EC2_SSM_Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach AmazonSSMManagedInstanceCore policy to the IAM role
resource "aws_iam_role_policy_attachment" "ec2_role_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.ec2_role.name
}

# Create an instance profile for the EC2 instance and associate the IAM role
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "EC2_SSM_Instance_Profile"

  role = aws_iam_role.ec2_role.name
}


# Create EC2 instance
resource "aws_instance" "ec2_instance" {
  ami           = data.aws_ami.amazon_linux_2_ssm.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_subnet[0].id
  vpc_security_group_ids = [
    aws_security_group.instance_security_group.id,
  ]
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
}
```

**7. Outputs**

Finalmente, agora adicionaremos algumas saídas em nosso código, faremos isso no arquivo ***outputs&period;tf***, para podermos ver os endereços que serão necessários na conexão com a nossa base de dados:

``` terraform
# Usuario da Base de Dados
output "db_username" {
  value = aws_db_instance.rds_instance.username
}

# Endpoint da base de dados
output "rds_endpoint" {
  value = aws_db_instance.rds_instance.address
}

# ID da instância EC2
output "instance_id" {
  value = aws_instance.ec2_instance.id
}
```

Feito tudo isso, basta rodar o comando abaixo e digitar ***yes*** (a instalação da infraestrutura vai demorar em torno de 5 a 8 minutos):
```
terraform apply
```

No terminal, deve ter aparecido algo como isto:

![Print terminal](/imgs/apply-terminal.png)

Guarde esse valores! Com eles nós iremos fazer nossa conexão com a base de dados!

### Testando nossa infraestrutura

**a. Realizando a conexão diretamente por CLI**

Uma maneira de testarmos nossa conexão é por meio do terminal e do MySQL CLI, para isso, primeiro nos conectamos a rede por SSM:

<span style="color:red"><span style="font-weight:700">IMPORTANTE:</span> Troque as variáveis pelos respectivos valores que apareceram em seu terminal!</span>

```
aws ssm start-session --region us-east-1 --target <INSTANCE_ID> --document-name AWS-StartPortForwardingSessionToRemoteHost --parameters host="<RDS_ENDPOINT>",portNumber="3306",localPortNumber="8001"
```

Agora, já é possível nos conectar com a base de dados! Em outro terminal, rode o seguinte comando substituindo *DB User* pelo usuario de sua base de dados! Após rodar o comando, a senha da base será requisitada, basta inseri-la que estaremos conectados!

```
mysql -u <DB User> -h 127.0.0.1 -P 8001 -p
```

Para verificarmos se tudo esta funcionando corretamente, basta rodar o seguinte comando:

```
show DATABASES;
```

A seguinte imagem deve aparecer:

![](/imgs/databases-terminal.png)


**b. Realizando a conexão pelo Python**

Para testarmos usando um ambiente python, também precisamos fazer a conexão SSM pelo terminal:

```
aws ssm start-session --region us-east-1 --target <INSTANCE_ID> --document-name AWS-StartPortForwardingSessionToRemoteHost --parameters host="<RDS_ENDPOINT>",portNumber="3306",localPortNumber="8001"
```

Agora para nos conectarmos a base em si, temos o _notebook_ ***pokemon_rds.ipynb*** pronto para isso, basta rodá-lo! Nele já estão os comandos envolvendo a instalação de pacotes necessários, apenas rode célula as células!


**c. Realizando a conexão pelo MySQL**

Finalmente, podemos realizar nossa conexão pelo MySQLWorkbench, ambiente mais propício para trabalhar com a base do que o terminal! Mais uma vez, precisamos fazer a conexão SSM pelo terminal:

```
aws ssm start-session --region us-east-1 --target <INSTANCE_ID> --document-name AWS-StartPortForwardingSessionToRemoteHost --parameters host="<RDS_ENDPOINT>",portNumber="3306",localPortNumber="8001"
```

Feito isso, abra o MySQL Workbench, e na tela inicial, clique no **+** para adicionarmos uma nova conexão.

![Print terminal](/imgs/mysql-telainicial.png)

Então, uma janela vai aparecer para configurarmos ela, o primeiro passo é garantir que o *Connection Method* está em *Standard TCP/IP*.

Aqui devemos fazer as seguintes mudanças **usando os valores dos outputs**:

**Port:** Porta usada para acessar os serviços, nós declaramos na conexão SSM que é a porta **8001**.

**Username:** É o *username* escolhido na criação de nossa base RDS, no meu caso, é **admin**.

**Password:** É o *password* escolhido na criação de nossa base RDS, no meu caso, é **adminrds**, para inseri-la, basta clicar em *Store in Vault..* .

Concluindo, sua janela deve estar de forma semelhante a esta:

![Criando conexão](/imgs/mysql-connection.png)


Por fim, basta clicar *Test Connection*, talvez apareça um warning, mas basta confiar na conexão, e então uma mensagem de sucesso irá aparecer na tela, feito isso basta clicar *Ok* e a sua conexão irá aparecer no seu dashboard:

![Conexão criada](/imgs/mysql-final.png)

Feito! Agora você já consegue acessar sua base de dados! Basta clicar na conexão criada:

![Conexão realizada](/imgs/mysql-base.png)

Terminamos! Aqui finalizamos nosso roteiro de implementação, se quiser destruir os recursos, primeiramente finalize a conexão SSM feita no terminal e depois basta rodar o seguinte comando, e digitar ***yes*** para confirmar:

```
terraform destroy
```

#### Referências


https://beabetterdev.com/2022/12/13/how-to-connect-to-an-rds-or-aurora-database-in-a-private-subnet/ 

https://dev.to/aws-builders/connecting-to-private-ec2-instances-using-systems-manager-a-hands-on-guide-33m

https://dev.to/aws-builders/how-to-set-up-session-manager-and-enable-ssh-over-ssm-43k9#:~:text=Go%20to%20EC2%20instances%2C%20select,created%20in%20the%20previous%20step

https://dev.to/aws-builders/securely-access-your-ec2-instances-with-aws-systems-manager-ssm-and-vpc-endpoints-1bli 

https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/tutorial-connect-ec2-instance-to-rds-database.html 

https://medium.com/strategio/using-terraform-to-create-aws-vpc-ec2-and-rds-instances-c7f3aa416133

