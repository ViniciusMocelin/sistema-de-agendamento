#!/bin/bash

# Script para iniciar todos os serviços AWS que geram cobrança
# Sistema de Agendamento - 4Minds

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações baseadas no terraform.tfstate
REGION="us-east-1"
PROJECT_NAME="sistema-agendamento"

# IDs dos recursos (extraídos do terraform.tfstate)
EC2_INSTANCE_ID="i-04d14b81170c26323"
RDS_INSTANCE_ID="sistema-agendamento-postgres"

echo -e "${BLUE}=== INICIANDO SERVIÇOS AWS - SISTEMA DE AGENDAMENTO ===${NC}"
echo -e "${BLUE}Região: ${REGION}${NC}"
echo -e "${BLUE}Projeto: ${PROJECT_NAME}${NC}"
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

# Função para iniciar instância EC2
start_ec2_instance() {
    echo -e "${YELLOW}Iniciando instância EC2...${NC}"
    
    # Verificar status atual
    CURRENT_STATE=$(aws ec2 describe-instances \
        --instance-ids $EC2_INSTANCE_ID \
        --region $REGION \
        --query 'Reservations[0].Instances[0].State.Name' \
        --output text)
    
    echo -e "${BLUE}Status atual da instância EC2: ${CURRENT_STATE}${NC}"
    
    if [ "$CURRENT_STATE" = "stopped" ]; then
        echo -e "${YELLOW}Iniciando instância EC2 (${EC2_INSTANCE_ID})...${NC}"
        aws ec2 start-instances \
            --instance-ids $EC2_INSTANCE_ID \
            --region $REGION \
            --output table
        
        echo -e "${YELLOW}Aguardando instância iniciar...${NC}"
        aws ec2 wait instance-running \
            --instance-ids $EC2_INSTANCE_ID \
            --region $REGION
        
        # Obter IP público
        PUBLIC_IP=$(aws ec2 describe-instances \
            --instance-ids $EC2_INSTANCE_ID \
            --region $REGION \
            --query 'Reservations[0].Instances[0].PublicIpAddress' \
            --output text)
        
        echo -e "${GREEN}✓ Instância EC2 iniciada com sucesso${NC}"
        echo -e "${GREEN}✓ IP Público: ${PUBLIC_IP}${NC}"
        echo -e "${GREEN}✓ URL da aplicação: http://${PUBLIC_IP}${NC}"
    elif [ "$CURRENT_STATE" = "running" ]; then
        echo -e "${YELLOW}✓ Instância EC2 já está rodando${NC}"
        
        # Obter IP público
        PUBLIC_IP=$(aws ec2 describe-instances \
            --instance-ids $EC2_INSTANCE_ID \
            --region $REGION \
            --query 'Reservations[0].Instances[0].PublicIpAddress' \
            --output text)
        echo -e "${GREEN}✓ IP Público: ${PUBLIC_IP}${NC}"
        echo -e "${GREEN}✓ URL da aplicação: http://${PUBLIC_IP}${NC}"
    elif [ "$CURRENT_STATE" = "pending" ]; then
        echo -e "${YELLOW}✓ Instância EC2 já está sendo iniciada${NC}"
        aws ec2 wait instance-running \
            --instance-ids $EC2_INSTANCE_ID \
            --region $REGION
        
        # Obter IP público
        PUBLIC_IP=$(aws ec2 describe-instances \
            --instance-ids $EC2_INSTANCE_ID \
            --region $REGION \
            --query 'Reservations[0].Instances[0].PublicIpAddress' \
            --output text)
        
        echo -e "${GREEN}✓ Instância EC2 iniciada com sucesso${NC}"
        echo -e "${GREEN}✓ IP Público: ${PUBLIC_IP}${NC}"
        echo -e "${GREEN}✓ URL da aplicação: http://${PUBLIC_IP}${NC}"
    else
        echo -e "${YELLOW}⚠ Instância EC2 está em estado: ${CURRENT_STATE}${NC}"
    fi
}

# Função para iniciar instância RDS
start_rds_instance() {
    echo -e "${YELLOW}Iniciando instância RDS...${NC}"
    
    # Verificar status atual
    CURRENT_STATE=$(aws rds describe-db-instances \
        --db-instance-identifier $RDS_INSTANCE_ID \
        --region $REGION \
        --query 'DBInstances[0].DBInstanceStatus' \
        --output text 2>/dev/null || echo "not-found")
    
    echo -e "${BLUE}Status atual da instância RDS: ${CURRENT_STATE}${NC}"
    
    if [ "$CURRENT_STATE" = "stopped" ]; then
        echo -e "${YELLOW}Iniciando instância RDS (${RDS_INSTANCE_ID})...${NC}"
        aws rds start-db-instance \
            --db-instance-identifier $RDS_INSTANCE_ID \
            --region $REGION \
            --output table
        
        echo -e "${YELLOW}Aguardando instância RDS iniciar...${NC}"
        aws rds wait db-instance-available \
            --db-instance-identifier $RDS_INSTANCE_ID \
            --region $REGION
        
        # Obter endpoint
        RDS_ENDPOINT=$(aws rds describe-db-instances \
            --db-instance-identifier $RDS_INSTANCE_ID \
            --region $REGION \
            --query 'DBInstances[0].Endpoint.Address' \
            --output text)
        
        echo -e "${GREEN}✓ Instância RDS iniciada com sucesso${NC}"
        echo -e "${GREEN}✓ Endpoint: ${RDS_ENDPOINT}${NC}"
    elif [ "$CURRENT_STATE" = "available" ]; then
        echo -e "${YELLOW}✓ Instância RDS já está rodando${NC}"
        
        # Obter endpoint
        RDS_ENDPOINT=$(aws rds describe-db-instances \
            --db-instance-identifier $RDS_INSTANCE_ID \
            --region $REGION \
            --query 'DBInstances[0].Endpoint.Address' \
            --output text)
        echo -e "${GREEN}✓ Endpoint: ${RDS_ENDPOINT}${NC}"
    elif [ "$CURRENT_STATE" = "starting" ]; then
        echo -e "${YELLOW}✓ Instância RDS já está sendo iniciada${NC}"
        aws rds wait db-instance-available \
            --db-instance-identifier $RDS_INSTANCE_ID \
            --region $REGION
        
        # Obter endpoint
        RDS_ENDPOINT=$(aws rds describe-db-instances \
            --db-instance-identifier $RDS_INSTANCE_ID \
            --region $REGION \
            --query 'DBInstances[0].Endpoint.Address' \
            --output text)
        
        echo -e "${GREEN}✓ Instância RDS iniciada com sucesso${NC}"
        echo -e "${GREEN}✓ Endpoint: ${RDS_ENDPOINT}${NC}"
    elif [ "$CURRENT_STATE" = "not-found" ]; then
        echo -e "${YELLOW}⚠ Instância RDS não encontrada${NC}"
    else
        echo -e "${YELLOW}⚠ Instância RDS está em estado: ${CURRENT_STATE}${NC}"
    fi
}

# Função para aguardar serviços ficarem prontos
wait_for_services() {
    echo -e "${YELLOW}Aguardando serviços ficarem prontos...${NC}"
    
    # Aguardar EC2
    if [ "$(aws ec2 describe-instances --instance-ids $EC2_INSTANCE_ID --region $REGION --query 'Reservations[0].Instances[0].State.Name' --output text)" = "running" ]; then
        echo -e "${YELLOW}Aguardando aplicação Django iniciar...${NC}"
        sleep 30
        
        # Obter IP público
        PUBLIC_IP=$(aws ec2 describe-instances \
            --instance-ids $EC2_INSTANCE_ID \
            --region $REGION \
            --query 'Reservations[0].Instances[0].PublicIpAddress' \
            --output text)
        
        # Testar se a aplicação está respondendo
        echo -e "${YELLOW}Testando conectividade da aplicação...${NC}"
        if curl -s --max-time 10 "http://${PUBLIC_IP}" > /dev/null; then
            echo -e "${GREEN}✓ Aplicação Django está respondendo${NC}"
        else
            echo -e "${YELLOW}⚠ Aplicação ainda não está respondendo (pode levar alguns minutos)${NC}"
        fi
    fi
}

# Função para mostrar status final
show_final_status() {
    echo ""
    echo -e "${BLUE}=== STATUS FINAL DOS SERVIÇOS ===${NC}"
    
    # Status EC2
    EC2_STATE=$(aws ec2 describe-instances \
        --instance-ids $EC2_INSTANCE_ID \
        --region $REGION \
        --query 'Reservations[0].Instances[0].State.Name' \
        --output text 2>/dev/null || echo "not-found")
    
    PUBLIC_IP=$(aws ec2 describe-instances \
        --instance-ids $EC2_INSTANCE_ID \
        --region $REGION \
        --query 'Reservations[0].Instances[0].PublicIpAddress' \
        --output text 2>/dev/null || echo "N/A")
    
    echo -e "${BLUE}EC2 (${EC2_INSTANCE_ID}): ${EC2_STATE} - IP: ${PUBLIC_IP}${NC}"
    
    # Status RDS
    RDS_STATE=$(aws rds describe-db-instances \
        --db-instance-identifier $RDS_INSTANCE_ID \
        --region $REGION \
        --query 'DBInstances[0].DBInstanceStatus' \
        --output text 2>/dev/null || echo "not-found")
    
    RDS_ENDPOINT=$(aws rds describe-db-instances \
        --db-instance-identifier $RDS_INSTANCE_ID \
        --region $REGION \
        --query 'DBInstances[0].Endpoint.Address' \
        --output text 2>/dev/null || echo "N/A")
    
    echo -e "${BLUE}RDS (${RDS_INSTANCE_ID}): ${RDS_STATE} - Endpoint: ${RDS_ENDPOINT}${NC}"
    
    echo ""
    echo -e "${GREEN}=== SERVIÇOS INICIADOS COM SUCESSO ===${NC}"
    
    if [ "$PUBLIC_IP" != "N/A" ] && [ "$PUBLIC_IP" != "None" ]; then
        echo -e "${GREEN}🌐 URL da aplicação: http://${PUBLIC_IP}${NC}"
        echo -e "${GREEN}🔑 Comando SSH: ssh -i ~/.ssh/id_rsa ubuntu@${PUBLIC_IP}${NC}"
    fi
    
    echo -e "${YELLOW}Nota: Aguarde alguns minutos para a aplicação ficar completamente pronta${NC}"
}

# Função principal
main() {
    echo -e "${BLUE}Iniciando processo de inicialização dos serviços...${NC}"
    
    check_aws_cli
    start_rds_instance
    start_ec2_instance
    wait_for_services
    show_final_status
}

# Executar função principal
main "$@"
