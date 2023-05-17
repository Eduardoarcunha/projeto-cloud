## Conexão do RDS da AWS com uma interface gráfica de base de dados
**Projeto de Computação em Nuvem**
**Aluno:** Eduardo Araujo Rodrigues da Cunha
**Data:** 26/05/2023


#### Objetivo de implantação

Este roteiro tem como objetivo conectar uma interface gráfica de banco de dados, por exemplo o MySQL Workbench, com um banco de dados RDS que é um serviço da amazon de banco de dados relacionais. 
A infraestrutura consiste em uma EC2 atuando como JumpBox para a base RDS.

#### Requisitos da implementação

**1.** Conta [AWS](https://aws.amazon.com/pt/) e credenciais para instalação da infraestrutura.

**2.** [Terraform](https://www.terraform.io/) instalado em sua máquina, essa é uma ferramenta de software de infraestrutura como código (IaC).

**3.** *Keypair* com o nome ***mykp***, pode ser gerada pelo seguinte comando:

```
ssh-keygen -t rsa -b 4096
```

**Observação:** (Caso queira testar a conexão por Workbench) [MySqlWorkbench](https://www.mysql.com/products/workbench/) instalado em sua máquina.


#### Tutorial da implementação

**1. Preparação do ambiente**

Antes de iniciarmos a implementação da infraestrutura em si, devemos preparar nosso ambiente de trabalho, para isso, basta criarmos uma pasta projeto e um arquivo *main&period;tf*.

Neste arquivo, primeiramente iremos referenciar qual o nosso provider, além de passarmos nossas credenciais da AWS.

Aqui também criaremos um bloco de dados para conseguirmos encontrar facilmente quais as zonas disponíveis da AWS para nossa região definida no provider (*us-east-1*).

Por fim, vamos adicionar uma variável para guardarmos os CIDR de nossas subredes privadas.

**Observação:** 
*Não coloque diretamente suas credencias no código, existem maneiras melhores de referenciá-las no arquivo, como usando variáveis de ambiente. Em nosso caso, estamos usando os arquivos de configuração do AWS CLI como referência, e evitando a exposição de nossas credenciais. Se quiser ver como configurar esses arquivos, confira [este tutorial da Amazon](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html).*

``` tf
provider "aws" {
  region = "us-east-1"
  shared_config_files      = ["C:/Users/eduar/.aws/config"]
  shared_credentials_files = ["C:/Users/eduar/.aws/credentials"]
}

data "aws_availability_zones" "available" {
  state = "available"
}

variable "private_subnets_cidr_blocks" {
  type = list(string)
  default = [
    "10.0.101.0/24",
    "10.0.102.0/24"
  ]
}
```

Antes de continuarmos, no terminal chegue até o diretório de trabalho e rode o seguinte comando:
```
terraform init
```

Após o comando, alguns arquivos serão criados no diretório, não precisamos nos preocupar com eles, para saber se a inicialização deu certo, a seguinte mensagem deve aparecer em seu terminal:

![Init terraform](/imgs/init-terraform.png)

Agora, voltando para nosso arquivo *main*, o próximo passo é criar nossa rede virtual (VPC) e também um gateway para ela:

```
# 1. Creating VPC
resource "aws_vpc" "rds_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "rds_vpc"
  }
}

# 2. Internet Gateway
resource "aws_internet_gateway" "rds_igw" {
  vpc_id = aws_vpc.rds_vpc.id

  tags = {
    Name = "rds_igw"
  }
}
```

Feito isso, partimos para a criação de uma subrede pública, e duas privadas, e suas tabelas de roteamento.

**Observação:** É necessário a criação de duas privadas pois para atrelarmos um grupo de subredes ao RDS esse grupo necessita de pelo menos duas subredes.

```
# 3. Public subnet
resource "aws_subnet" "rds_subnet_public" {
  vpc_id            = aws_vpc.rds_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "rds_subnet_public"
  }
}

# 4. Private subnet
resource "aws_subnet" "rds_subnet_private" {
  count = 2
  vpc_id            = aws_vpc.rds_vpc.id
  cidr_block        = var.private_subnets_cidr_blocks[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "rds_subnet_private"
  }
}

# 5. Public route table
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

# 6. Private route table
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
```

Agora, criaremos os grupos de segurança para nossa EC2 e para nosso banco de dados, a instância EC2 deve ser acessível por *HTTPS*, *HTTP* e *SSH*, enquanto a base RDS só pode ser acessível pela instância EC2:

**Observação:** Como neste exemplo estamos trabalhando com um banco de dados SQL, a porta do serviço é 3306, mas esse valor pode mudar.

```
# 7. EC2 security group
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

#8. RDS security group
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

**Importante:** Note que é aqui que estamos definindo o usuário e a senha de nosso banco de dados, lembre-se de guardar esses valores para nos conectarmos na base no futuro.

```
#9. RDS subnet group
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds_subnet_group"
  subnet_ids = [for subnet in aws_subnet.rds_subnet_private : subnet.id]
}

# 10. RDS instance
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

```
ssh-keygen -t rsa -b 4096
```

Ao rodar o comando, escolha um nome para os arquivos em que serão salvas suas chaves, neste momento, seu projeto deve estar da seguinte maneira:

![Estrutura projeto](/imgs/estrutura-projeto.png)


Feito isso, agora devemos criar nossa instância EC2, referenciar nossa chave privada (o arquivo com extensão *.pub*) e criar um Elastic IP para nossa instância:

**Cuidado:** Se atente em como você está referenciando sua chave em *public_key*

```
# 11. Key pair
resource "aws_key_pair" "rds_ec2_key_pair" {
  key_name = "rds_kp"
  public_key = file("./chaves.pub")
}

# 12. EC2 instance
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

# 13. Elastic IP
resource "aws_eip" "rds_eip" {
  vpc = true
  instance = aws_instance.ec2_instance.id

  tags = {
    Name = "rds_eip"
  }
}
```

Finalmente, agora adicionaremos alguns *outputs*, para podermos ver os endereços que serão necessários na conexão com a nossa base de dados:

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
terraform apply -var-file="secrets.tfvars"
```

No terminal, deve ter aparecido algo como isto (a instalação da infraestrutura vai demorar em torno de 5 minutos):

![Print terminal](/imgs/apply-feito.png)

Guarde esse valores! Com eles nós iremos fazer nossa conexão com a base de dados!

#### Realizando a conexão diretamente por CLI

Uma maneira alternativa para testarmos nossa conexão é fazer ssh para nossa EC2, e então nos conectarmos a base, para isso, basta rodar o seguinte comando no terminal:

```
ssh -i "mykp" ubuntu@$(terraform output -raw public_ip)
```

Feito isso, agora estamos em nossa EC2 a qual tem acesso ao banco de dados.

Agora basta rodar o seguinte comando, substituindo os valores em cochetes pela endpoint da nossa RDS, da porta de acesso (3306), e pelo usuario definido na criação da RDS.

```
mysql -h <database-endpoint> -P <port> -u <db-username> -p
```

Para verificarmos se tudo esta funcionando corretamente, basta rodar o seguinte comando:

```
show DATABASES;
```



#### Realizando a conexão pelo MySQL

Agora, podemos finalmente realizar nossa conexão, o que acontece é que realizaremos um túnel com nossa base de dados a partir da nossa instância EC2. 

Como estamos usando o MySqlWorkbench, conseguimos realizar esse túnel pela própria ferramenta.

Ta tela inicial do MySql, iremos criam no **+** e adicionar uma nova conexão.

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

Terminamos! Aqui finalizamos nosso roteiro de implementação, se quiser destruir os recursos criados na AWS basta apagar o código criado com exceção do recurso *provider* e então rodar o comando terraform apply mais uma vez"

#### Referências

https://medium.com/strategio/using-terraform-to-create-aws-vpc-ec2-and-rds-instances-c7f3aa416133

https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/tutorial-connect-ec2-instance-to-rds-database.html 

https://beabetterdev.com/2022/12/13/how-to-connect-to-an-rds-or-aurora-database-in-a-private-subnet/ 