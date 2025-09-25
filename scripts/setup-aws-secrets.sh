#!/bin/bash

# Script para configurar AWS Secrets Manager
# Sistema de Agendamento - 4Minds

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações
REGION="us-east-1"
PROJECT_NAME="sistema-agendamento"

echo -e "${BLUE}=== CONFIGURANDO AWS SECRETS MANAGER ===${NC}"
echo -e "${BLUE}Projeto: ${PROJECT_NAME}${NC}"
echo -e "${BLUE}Região: ${REGION}${NC}"
echo ""

# Função para verificar se o AWS CLI está configurado
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}ERRO: AWS CLI não está instalado ou não está no PATH${NC}"
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        echo -e "${RED}ERRO: AWS CLI não está configurado ou credenciais inválidas${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ AWS CLI configurado corretamente${NC}"
}

# Função para criar secret para SECRET_KEY do Django
create_django_secret() {
    echo -e "${YELLOW}Criando secret para SECRET_KEY do Django...${NC}"
    
    # Verificar se secret já existe
    if aws secretsmanager describe-secret --secret-id "${PROJECT_NAME}/django-secret" --region $REGION &> /dev/null; then
        echo -e "${YELLOW}✓ Secret ${PROJECT_NAME}/django-secret já existe${NC}"
        
        # Perguntar se quer atualizar
        read -p "Deseja atualizar o secret existente? (s/n): " update_choice
        if [[ $update_choice =~ ^[Ss]$ ]]; then
            echo -e "${YELLOW}Digite a nova SECRET_KEY:${NC}"
            read -s django_secret
            
            aws secretsmanager update-secret \
                --secret-id "${PROJECT_NAME}/django-secret" \
                --secret-string "$django_secret" \
                --region $REGION \
                --output table
            
            echo -e "${GREEN}✓ Secret atualizado com sucesso${NC}"
        fi
    else
        echo -e "${YELLOW}Digite a SECRET_KEY do Django:${NC}"
        read -s django_secret
        
        aws secretsmanager create-secret \
            --name "${PROJECT_NAME}/django-secret" \
            --description "Secret key do Django para ${PROJECT_NAME}" \
            --secret-string "$django_secret" \
            --region $REGION \
            --output table
        
        echo -e "${GREEN}✓ Secret criado com sucesso${NC}"
    fi
}

# Função para criar secret para senha do banco de dados
create_db_password_secret() {
    echo -e "${YELLOW}Criando secret para senha do banco de dados...${NC}"
    
    # Verificar se secret já existe
    if aws secretsmanager describe-secret --secret-id "${PROJECT_NAME}/db-password" --region $REGION &> /dev/null; then
        echo -e "${YELLOW}✓ Secret ${PROJECT_NAME}/db-password já existe${NC}"
        
        # Perguntar se quer atualizar
        read -p "Deseja atualizar o secret existente? (s/n): " update_choice
        if [[ $update_choice =~ ^[Ss]$ ]]; then
            echo -e "${YELLOW}Digite a nova senha do banco:${NC}"
            read -s db_password
            
            aws secretsmanager update-secret \
                --secret-id "${PROJECT_NAME}/db-password" \
                --secret-string "$db_password" \
                --region $REGION \
                --output table
            
            echo -e "${GREEN}✓ Secret atualizado com sucesso${NC}"
        fi
    else
        echo -e "${YELLOW}Digite a senha do banco de dados:${NC}"
        read -s db_password
        
        aws secretsmanager create-secret \
            --name "${PROJECT_NAME}/db-password" \
            --description "Senha do banco de dados PostgreSQL para ${PROJECT_NAME}" \
            --secret-string "$db_password" \
            --region $REGION \
            --output table
        
        echo -e "${GREEN}✓ Secret criado com sucesso${NC}"
    fi
}

# Função para criar secret para credenciais de email
create_email_secret() {
    echo -e "${YELLOW}Criando secret para credenciais de email...${NC}"
    
    # Verificar se secret já existe
    if aws secretsmanager describe-secret --secret-id "${PROJECT_NAME}/email-credentials" --region $REGION &> /dev/null; then
        echo -e "${YELLOW}✓ Secret ${PROJECT_NAME}/email-credentials já existe${NC}"
        
        # Perguntar se quer atualizar
        read -p "Deseja atualizar o secret existente? (s/n): " update_choice
        if [[ $update_choice =~ ^[Ss]$ ]]; then
            echo -e "${YELLOW}Digite o email:${NC}"
            read email_user
            echo -e "${YELLOW}Digite a senha do email:${NC}"
            read -s email_password
            
            email_credentials=$(cat <<EOF
{
    "email": "$email_user",
    "password": "$email_password"
}
EOF
)
            
            aws secretsmanager update-secret \
                --secret-id "${PROJECT_NAME}/email-credentials" \
                --secret-string "$email_credentials" \
                --region $REGION \
                --output table
            
            echo -e "${GREEN}✓ Secret atualizado com sucesso${NC}"
        fi
    else
        echo -e "${YELLOW}Digite o email:${NC}"
        read email_user
        echo -e "${YELLOW}Digite a senha do email:${NC}"
        read -s email_password
        
        email_credentials=$(cat <<EOF
{
    "email": "$email_user",
    "password": "$email_password"
}
EOF
)
        
        aws secretsmanager create-secret \
            --name "${PROJECT_NAME}/email-credentials" \
            --description "Credenciais de email para ${PROJECT_NAME}" \
            --secret-string "$email_credentials" \
            --region $REGION \
            --output table
        
        echo -e "${GREEN}✓ Secret criado com sucesso${NC}"
    fi
}

# Função para listar secrets criados
list_secrets() {
    echo -e "${YELLOW}Listando secrets criados...${NC}"
    
    aws secretsmanager list-secrets \
        --region $REGION \
        --query "SecretList[?contains(Name, '${PROJECT_NAME}')].{Name:Name,Description:Description,CreatedDate:CreatedDate}" \
        --output table
    
    echo ""
}

# Função para mostrar instruções de uso
show_usage_instructions() {
    echo -e "${BLUE}=== INSTRUÇÕES DE USO ===${NC}"
    echo ""
    echo -e "${YELLOW}Para usar os secrets no código Python:${NC}"
    echo ""
    echo -e "${GREEN}# Exemplo de uso no Django settings${NC}"
    echo "import boto3"
    echo "import json"
    echo ""
    echo "def get_secret(secret_name):"
    echo "    client = boto3.client('secretsmanager', region_name='${REGION}')"
    echo "    response = client.get_secret_value(SecretId=secret_name)"
    echo "    return response['SecretString']"
    echo ""
    echo "# Uso:"
    echo "SECRET_KEY = get_secret('${PROJECT_NAME}/django-secret')"
    echo "DB_PASSWORD = get_secret('${PROJECT_NAME}/db-password')"
    echo ""
    echo -e "${YELLOW}Para usar no user_data.sh da EC2:${NC}"
    echo ""
    echo "DB_PASSWORD=\$(aws secretsmanager get-secret-value \\"
    echo "    --secret-id ${PROJECT_NAME}/db-password \\"
    echo "    --region ${REGION} \\"
    echo "    --query SecretString --output text)"
    echo ""
    echo -e "${BLUE}================================${NC}"
}

# Função principal
main() {
    echo -e "${BLUE}Iniciando configuração do AWS Secrets Manager...${NC}"
    
    check_aws_cli
    
    echo ""
    echo -e "${YELLOW}Secrets que serão criados:${NC}"
    echo "1. ${PROJECT_NAME}/django-secret (SECRET_KEY do Django)"
    echo "2. ${PROJECT_NAME}/db-password (Senha do banco de dados)"
    echo "3. ${PROJECT_NAME}/email-credentials (Credenciais de email)"
    echo ""
    
    read -p "Continuar? (s/n): " continue_choice
    if [[ ! $continue_choice =~ ^[Ss]$ ]]; then
        echo -e "${YELLOW}Operação cancelada${NC}"
        exit 0
    fi
    
    create_django_secret
    create_db_password_secret
    create_email_secret
    
    echo ""
    list_secrets
    show_usage_instructions
    
    echo -e "${GREEN}=== CONFIGURAÇÃO CONCLUÍDA ===${NC}"
}

# Executar função principal
main "$@"
