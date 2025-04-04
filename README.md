# 📌 Configuração de Notificações e Logs para um Bucket S3 usando SNS e SQS

## 📖 Visão Geral
Este projeto configura notificações por e-mail (**SNS**) e mantém um registro de eventos (**SQS**) para **uploads e exclusões de arquivos** em um bucket **Amazon S3**.

### 🎯 Objetivos:
1. **Receber notificações por e-mail** sempre que um arquivo for **carregado (upload)** ou **excluído (delete)** no bucket S3.
2. **Registrar logs desses eventos** em uma **fila SQS**, permitindo análise posterior.

## 🏗️ Arquitetura
A solução utiliza os seguintes serviços AWS:
- **Amazon S3**: Armazena os arquivos e gera eventos quando um arquivo é adicionado ou removido.
- **Amazon SNS (Simple Notification Service)**: Envia notificações por e-mail quando eventos ocorrem.
- **Amazon SQS (Simple Queue Service)**: Mantém um registro de eventos para análise posterior.
- **Terraform**: Usado para provisionar toda a infraestrutura na AWS.

---

## ⚙️ Configuração com Terraform

### 1️⃣ **Configurar o Provider AWS**
```hcl
provider "aws" {
  region = "us-east-1"
}
```

### 2️⃣ **Criar o Bucket S3**
```hcl
resource "aws_s3_bucket" "example" {
  bucket = "meu-bucket-com-email-alerta"
}
```

### 3️⃣ **Criar o Tópico SNS para Notificações**
```hcl
resource "aws_sns_topic" "s3_notifications" {
  name = "s3-events-topic"
}
```

### 4️⃣ **Inscrever um E-mail no SNS**
```hcl
resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.s3_notifications.arn
  protocol  = "email"
  endpoint  = "seu@email.com"  # <-- Altere para seu e-mail real
}
```
📌 **Importante**: Confirme a inscrição no e-mail recebido.

### 5️⃣ **Criar uma Fila SQS para Armazenar Eventos**
```hcl
resource "aws_sqs_queue" "s3_event_queue" {
  name = "s3-event-queue"
}
```

### 6️⃣ **Configurar Permissões para o S3 Publicar no SNS e SQS**
```hcl
resource "aws_sns_topic_policy" "sns_policy" {
  arn    = aws_sns_topic.s3_notifications.arn
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowS3Publish",
        Effect    = "Allow",
        Principal = { "Service": "s3.amazonaws.com" },
        Action   = "SNS:Publish",
        Resource = aws_sns_topic.s3_notifications.arn,
        Condition = { "StringEquals": { "aws:SourceArn": aws_s3_bucket.example.arn } }
      }
    ]
  })
}
```
```hcl
resource "aws_sqs_queue_policy" "s3_event_queue_policy" {
  queue_url = aws_sqs_queue.s3_event_queue.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = "*",
        Action = "sqs:SendMessage",
        Resource = aws_sqs_queue.s3_event_queue.arn,
        Condition = { "ArnEquals": { "aws:SourceArn": aws_s3_bucket.example.arn } }
      }
    ]
  })
}
```

### 7️⃣ **Configurar Notificações no S3**
```hcl
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.example.id

  topic {
    topic_arn = aws_sns_topic.s3_notifications.arn
    events    = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
  }

  queue {
    queue_arn = aws_sqs_queue.s3_event_queue.arn
    events    = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
  }

  depends_on = [aws_sns_topic_policy.sns_policy, aws_sqs_queue_policy.s3_event_queue_policy]
}
```

---

## 🛠️ Testando a Configuração

### 🔹 **Teste de Upload**
```bash
echo "teste" > arquivo.txt
aws s3 cp arquivo.txt s3://meu-bucket-com-email-alerta/
```
📬 Você deve receber um e-mail de notificação.  
📥 O evento deve aparecer na fila SQS.

### 🔹 **Teste de Exclusão**
```bash
aws s3 rm s3://meu-bucket-com-email-alerta/arquivo.txt
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
