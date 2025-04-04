# 📌 Configuração de Notificações e Logs para um Bucket S3 usando SNS e SQS

## 📖 Visão Geral
Este projeto configura notificações por e-mail (via **SNS**) e mantém um log de eventos (via **SQS**) para uploads e exclusões de arquivos em um bucket **Amazon S3**.

### 🎯 Objetivos:
1. **Receber notificações por e-mail** sempre que um arquivo for **carregado (upload)** ou **excluído (delete)** no bucket S3.
2. **Registrar logs desses eventos** em uma **fila SQS**, permitindo análise posterior.

## 🏗️ Arquitetura
A solução utiliza os seguintes serviços AWS:
- **Amazon S3**: Armazena os arquivos e gera eventos quando um arquivo é adicionado ou removido.
- **Amazon SNS (Simple Notification Service)**: Envia notificações por e-mail quando eventos ocorrem.
- **Amazon SQS (Simple Queue Service)**: Mantém um registro de eventos para análise posterior.

![Arquitetura](https://upload.wikimedia.org/wikipedia/commons/8/85/AWS_Simple_Notification_Service_%28SNS%29.png)  
*(Imagem ilustrativa do SNS. Adapte conforme necessário.)*

---

## ⚙️ Configuração

### 1️⃣ Criar um Bucket no S3
```bash
aws s3 mb s3://meu-bucket-de-midia
```

### 2️⃣ Criar um Tópico SNS para Notificações
```bash
aws sns create-topic --name s3-notificacoes
```
Anote o **ARN** do tópico SNS retornado.

### 3️⃣ Inscrever um E-mail no SNS
```bash
aws sns subscribe \
    --topic-arn arn:aws:sns:REGIAO:ID_CONTA:s3-notificacoes \
    --protocol email \
    --notification-endpoint seu@email.com
```
📌 **Importante**: Confirme a inscrição no e-mail recebido.

### 4️⃣ Criar uma Fila SQS para Logs
```bash
aws sqs create-queue --queue-name s3-eventos-logs
```
Anote o **ARN** da fila retornada.

### 5️⃣ Configurar Permissões para o S3 Publicar no SNS e SQS
Edite a política do bucket S3 para permitir eventos:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {"Service": "s3.amazonaws.com"},
            "Action": "sns:Publish",
            "Resource": "arn:aws:sns:REGIAO:ID_CONTA:s3-notificacoes"
        }
    ]
}
```

### 6️⃣ Configurar Eventos do S3 para Disparar SNS e SQS
```bash
aws s3api put-bucket-notification-configuration \
    --bucket meu-bucket-de-midia \
    --notification-configuration '{
        "TopicConfigurations": [
            {
                "TopicArn": "arn:aws:sns:REGIAO:ID_CONTA:s3-notificacoes",
                "Events": ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
            }
        ],
        "QueueConfigurations": [
            {
                "QueueArn": "arn:aws:sqs:REGIAO:ID_CONTA:s3-eventos-logs",
                "Events": ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
            }
        ]
    }'
```

---

## 🛠️ Teste da Configuração

### 🔹 Teste de Upload
```bash
echo "teste" > arquivo.txt
aws s3 cp arquivo.txt s3://meu-bucket-de-midia/
```
📬 Você deve receber um e-mail de notificação.
📥 O evento deve aparecer na fila SQS.

### 🔹 Teste de Exclusão
```bash
aws s3 rm s3://meu-bucket-de-midia/arquivo.txt
```
📬 Outra notificação por e-mail.
📥 Outro evento na fila SQS.

---

## 🚀 Conclusão
Agora você tem uma infraestrutura na AWS que **notifica via e-mail** e **armazena logs em uma fila SQS** sempre que arquivos são adicionados ou removidos de um bucket S3. Isso é útil para **monitoramento, auditoria e segurança**.

Se precisar de melhorias, como filtrar tipos específicos de arquivos ou acionar lambdas, essa configuração pode ser facilmente estendida! 🎯

---

## 📜 Referências
- [Amazon S3 Notifications](https://docs.aws.amazon.com/AmazonS3/latest/userguide/NotificationHowTo.html)
- [Amazon SNS Documentation](https://docs.aws.amazon.com/sns/latest/dg/welcome.html)
- [Amazon SQS Documentation](https://docs.aws.amazon.com/sqs/latest/dg/welcome.html)

🚀 **Desenvolvido por [Caio Nunes]**
