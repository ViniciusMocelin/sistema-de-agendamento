#!/bin/bash

# Script para parar todos os serviços AWS que geram cobrança
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

echo -e "${BLUE}=== PARANDO SERVIÇOS AWS - SISTEMA DE AGENDAMENTO ===${NC}"
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

# Função para parar instância EC2
stop_ec2_instance() {
    echo -e "${YELLOW}Parando instância EC2...${NC}"
    
    # Verificar status atual
    CURRENT_STATE=$(aws ec2 describe-instances \
        --instance-ids $EC2_INSTANCE_ID \
        --region $REGION \
        --query 'Reservations[0].Instances[0].State.Name' \
        --output text)
    
    echo -e "${BLUE}Status atual da instância EC2: ${CURRENT_STATE}${NC}"
    
    if [ "$CURRENT_STATE" = "running" ]; then
        echo -e "${YELLOW}Parando instância EC2 (${EC2_INSTANCE_ID})...${NC}"
        aws ec2 stop-instances \
            --instance-ids $EC2_INSTANCE_ID \
            --region $REGION \
            --output table
        
        echo -e "${YELLOW}Aguardando instância parar...${NC}"
        aws ec2 wait instance-stopped \
            --instance-ids $EC2_INSTANCE_ID \
            --region $REGION
        
        echo -e "${GREEN}✓ Instância EC2 parada com sucesso${NC}"
    elif [ "$CURRENT_STATE" = "stopped" ]; then
        echo -e "${YELLOW}✓ Instância EC2 já está parada${NC}"
    elif [ "$CURRENT_STATE" = "stopping" ]; then
        echo -e "${YELLOW}✓ Instância EC2 já está sendo parada${NC}"
        aws ec2 wait instance-stopped \
            --instance-ids $EC2_INSTANCE_ID \
            --region $REGION
        echo -e "${GREEN}✓ Instância EC2 parada com sucesso${NC}"
    else
        echo -e "${YELLOW}⚠ Instância EC2 está em estado: ${CURRENT_STATE}${NC}"
    fi
}

# Função para parar instância RDS
stop_rds_instance() {
    echo -e "${YELLOW}Parando instância RDS...${NC}"
    
    # Verificar status atual
    CURRENT_STATE=$(aws rds describe-db-instances \
        --db-instance-identifier $RDS_INSTANCE_ID \
        --region $REGION \
        --query 'DBInstances[0].DBInstanceStatus' \
        --output text 2>/dev/null || echo "not-found")
    
    echo -e "${BLUE}Status atual da instância RDS: ${CURRENT_STATE}${NC}"
    
    if [ "$CURRENT_STATE" = "available" ]; then
        echo -e "${YELLOW}Parando instância RDS (${RDS_INSTANCE_ID})...${NC}"
        aws rds stop-db-instance \
            --db-instance-identifier $RDS_INSTANCE_ID \
            --region $REGION \
            --output table
        
        echo -e "${YELLOW}Aguardando instância RDS parar...${NC}"
        aws rds wait db-instance-stopped \
            --db-instance-identifier $RDS_INSTANCE_ID \
            --region $REGION
        
        echo -e "${GREEN}✓ Instância RDS parada com sucesso${NC}"
    elif [ "$CURRENT_STATE" = "stopped" ]; then
        echo -e "${YELLOW}✓ Instância RDS já está parada${NC}"
    elif [ "$CURRENT_STATE" = "stopping" ]; then
        echo -e "${YELLOW}✓ Instância RDS já está sendo parada${NC}"
        aws rds wait db-instance-stopped \
            --db-instance-identifier $RDS_INSTANCE_ID \
            --region $REGION
        echo -e "${GREEN}✓ Instância RDS parada com sucesso${NC}"
    elif [ "$CURRENT_STATE" = "not-found" ]; then
        echo -e "${YELLOW}⚠ Instância RDS não encontrada${NC}"
    else
        echo -e "${YELLOW}⚠ Instância RDS está em estado: ${CURRENT_STATE}${NC}"
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
    echo -e "${BLUE}EC2 (${EC2_INSTANCE_ID}): ${EC2_STATE}${NC}"
    
    # Status RDS
    RDS_STATE=$(aws rds describe-db-instances \
        --db-instance-identifier $RDS_INSTANCE_ID \
        --region $REGION \
        --query 'DBInstances[0].DBInstanceStatus' \
        --output text 2>/dev/null || echo "not-found")
    echo -e "${BLUE}RDS (${RDS_INSTANCE_ID}): ${RDS_STATE}${NC}"
    
    echo ""
    echo -e "${GREEN}=== SERVIÇOS PARADOS COM SUCESSO ===${NC}"
    echo -e "${YELLOW}Nota: S3, CloudWatch Logs, SNS e outros serviços continuam ativos${NC}"
    echo -e "${YELLOW}Para parar completamente todos os recursos, execute: terraform destroy${NC}"
}

# Função principal
main() {
    echo -e "${BLUE}Iniciando processo de parada dos serviços...${NC}"
    
    check_aws_cli
    stop_ec2_instance
    stop_rds_instance
    show_final_status
}

# Executar função principal
main "$@"
