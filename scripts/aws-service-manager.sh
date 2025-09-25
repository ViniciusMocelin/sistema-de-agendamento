#!/bin/bash

# Script principal para gerenciar serviços AWS (parar/iniciar)
# Sistema de Agendamento - 4Minds

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configurações
REGION="us-east-1"
PROJECT_NAME="sistema-agendamento"
EC2_INSTANCE_ID="i-04d14b81170c26323"
RDS_INSTANCE_ID="sistema-agendamento-postgres"

# Função para mostrar banner
show_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                GERENCIADOR DE SERVIÇOS AWS                  ║"
    echo "║              Sistema de Agendamento - 4Minds                ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Função para mostrar menu
show_menu() {
    echo -e "${BLUE}Opções disponíveis:${NC}"
    echo -e "${GREEN}1)${NC} Parar todos os serviços (EC2 + RDS)"
    echo -e "${GREEN}2)${NC} Iniciar todos os serviços (EC2 + RDS)"
    echo -e "${GREEN}3)${NC} Parar apenas instância EC2"
    echo -e "${GREEN}4)${NC} Iniciar apenas instância EC2"
    echo -e "${GREEN}5)${NC} Parar apenas instância RDS"
    echo -e "${GREEN}6)${NC} Iniciar apenas instância RDS"
    echo -e "${GREEN}7)${NC} Verificar status dos serviços"
    echo -e "${GREEN}8)${NC} Mostrar informações dos recursos"
    echo -e "${GREEN}9)${NC} Sair"
    echo ""
}

# Função para verificar AWS CLI
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}ERRO: AWS CLI não está instalado ou não está no PATH${NC}"
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        echo -e "${RED}ERRO: AWS CLI não está configurado ou credenciais inválidas${NC}"
        exit 1
    fi
}

# Função para parar EC2
stop_ec2() {
    echo -e "${YELLOW}Parando instância EC2...${NC}"
    
    CURRENT_STATE=$(aws ec2 describe-instances \
        --instance-ids $EC2_INSTANCE_ID \
        --region $REGION \
        --query 'Reservations[0].Instances[0].State.Name' \
        --output text)
    
    if [ "$CURRENT_STATE" = "running" ]; then
        aws ec2 stop-instances \
            --instance-ids $EC2_INSTANCE_ID \
            --region $REGION \
            --output table
        
        aws ec2 wait instance-stopped \
            --instance-ids $EC2_INSTANCE_ID \
            --region $REGION
        
        echo -e "${GREEN}✓ Instância EC2 parada com sucesso${NC}"
    elif [ "$CURRENT_STATE" = "stopped" ]; then
        echo -e "${YELLOW}✓ Instância EC2 já está parada${NC}"
    else
        echo -e "${YELLOW}⚠ Instância EC2 está em estado: ${CURRENT_STATE}${NC}"
    fi
}

# Função para iniciar EC2
start_ec2() {
    echo -e "${YELLOW}Iniciando instância EC2...${NC}"
    
    CURRENT_STATE=$(aws ec2 describe-instances \
        --instance-ids $EC2_INSTANCE_ID \
        --region $REGION \
        --query 'Reservations[0].Instances[0].State.Name' \
        --output text)
    
    if [ "$CURRENT_STATE" = "stopped" ]; then
        aws ec2 start-instances \
            --instance-ids $EC2_INSTANCE_ID \
            --region $REGION \
            --output table
        
        aws ec2 wait instance-running \
            --instance-ids $EC2_INSTANCE_ID \
            --region $REGION
        
        PUBLIC_IP=$(aws ec2 describe-instances \
            --instance-ids $EC2_INSTANCE_ID \
            --region $REGION \
            --query 'Reservations[0].Instances[0].PublicIpAddress' \
            --output text)
        
        echo -e "${GREEN}✓ Instância EC2 iniciada com sucesso${NC}"
        echo -e "${GREEN}✓ IP Público: ${PUBLIC_IP}${NC}"
    elif [ "$CURRENT_STATE" = "running" ]; then
        echo -e "${YELLOW}✓ Instância EC2 já está rodando${NC}"
        PUBLIC_IP=$(aws ec2 describe-instances \
            --instance-ids $EC2_INSTANCE_ID \
            --region $REGION \
            --query 'Reservations[0].Instances[0].PublicIpAddress' \
            --output text)
        echo -e "${GREEN}✓ IP Público: ${PUBLIC_IP}${NC}"
    else
        echo -e "${YELLOW}⚠ Instância EC2 está em estado: ${CURRENT_STATE}${NC}"
    fi
}

# Função para parar RDS
stop_rds() {
    echo -e "${YELLOW}Parando instância RDS...${NC}"
    
    CURRENT_STATE=$(aws rds describe-db-instances \
        --db-instance-identifier $RDS_INSTANCE_ID \
        --region $REGION \
        --query 'DBInstances[0].DBInstanceStatus' \
        --output text 2>/dev/null || echo "not-found")
    
    if [ "$CURRENT_STATE" = "available" ]; then
        aws rds stop-db-instance \
            --db-instance-identifier $RDS_INSTANCE_ID \
            --region $REGION \
            --output table
        
        aws rds wait db-instance-stopped \
            --db-instance-identifier $RDS_INSTANCE_ID \
            --region $REGION
        
        echo -e "${GREEN}✓ Instância RDS parada com sucesso${NC}"
    elif [ "$CURRENT_STATE" = "stopped" ]; then
        echo -e "${YELLOW}✓ Instância RDS já está parada${NC}"
    else
        echo -e "${YELLOW}⚠ Instância RDS está em estado: ${CURRENT_STATE}${NC}"
    fi
}

# Função para iniciar RDS
start_rds() {
    echo -e "${YELLOW}Iniciando instância RDS...${NC}"
    
    CURRENT_STATE=$(aws rds describe-db-instances \
        --db-instance-identifier $RDS_INSTANCE_ID \
        --region $REGION \
        --query 'DBInstances[0].DBInstanceStatus' \
        --output text 2>/dev/null || echo "not-found")
    
    if [ "$CURRENT_STATE" = "stopped" ]; then
        aws rds start-db-instance \
            --db-instance-identifier $RDS_INSTANCE_ID \
            --region $REGION \
            --output table
        
        aws rds wait db-instance-available \
            --db-instance-identifier $RDS_INSTANCE_ID \
            --region $REGION
        
        RDS_ENDPOINT=$(aws rds describe-db-instances \
            --db-instance-identifier $RDS_INSTANCE_ID \
            --region $REGION \
            --query 'DBInstances[0].Endpoint.Address' \
            --output text)
        
        echo -e "${GREEN}✓ Instância RDS iniciada com sucesso${NC}"
        echo -e "${GREEN}✓ Endpoint: ${RDS_ENDPOINT}${NC}"
    elif [ "$CURRENT_STATE" = "available" ]; then
        echo -e "${YELLOW}✓ Instância RDS já está rodando${NC}"
        RDS_ENDPOINT=$(aws rds describe-db-instances \
            --db-instance-identifier $RDS_INSTANCE_ID \
            --region $REGION \
            --query 'DBInstances[0].Endpoint.Address' \
            --output text)
        echo -e "${GREEN}✓ Endpoint: ${RDS_ENDPOINT}${NC}"
    else
        echo -e "${YELLOW}⚠ Instância RDS está em estado: ${CURRENT_STATE}${NC}"
    fi
}

# Função para verificar status
check_status() {
    echo -e "${BLUE}=== STATUS DOS SERVIÇOS ===${NC}"
    echo ""
    
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
    
    echo -e "${CYAN}EC2 Instance:${NC}"
    echo -e "  ID: ${EC2_INSTANCE_ID}"
    echo -e "  Status: ${EC2_STATE}"
    echo -e "  IP Público: ${PUBLIC_IP}"
    if [ "$PUBLIC_IP" != "N/A" ] && [ "$PUBLIC_IP" != "None" ]; then
        echo -e "  URL: http://${PUBLIC_IP}"
    fi
    echo ""
    
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
    
    echo -e "${CYAN}RDS Instance:${NC}"
    echo -e "  ID: ${RDS_INSTANCE_ID}"
    echo -e "  Status: ${RDS_STATE}"
    echo -e "  Endpoint: ${RDS_ENDPOINT}"
    echo ""
}

# Função para mostrar informações dos recursos
show_resource_info() {
    echo -e "${BLUE}=== INFORMAÇÕES DOS RECURSOS ===${NC}"
    echo ""
    echo -e "${CYAN}Configuração:${NC}"
    echo -e "  Região: ${REGION}"
    echo -e "  Projeto: ${PROJECT_NAME}"
    echo ""
    echo -e "${CYAN}Recursos principais:${NC}"
    echo -e "  EC2 Instance ID: ${EC2_INSTANCE_ID}"
    echo -e "  RDS Instance ID: ${RDS_INSTANCE_ID}"
    echo ""
    echo -e "${CYAN}Outros recursos (não cobrados quando parados):${NC}"
    echo -e "  S3 Bucket: sistema-agendamento-static-files-dknda48q"
    echo -e "  CloudWatch Log Group: /aws/ec2/sistema-agendamento/django"
    echo -e "  SNS Topic: sistema-agendamento-alerts"
    echo -e "  Security Groups, VPC, Subnets, etc."
    echo ""
    echo -e "${YELLOW}Nota: S3, CloudWatch e outros serviços continuam ativos mesmo quando EC2/RDS estão parados${NC}"
}

# Função para executar opções do menu
execute_option() {
    local option=$1
    
    case $option in
        1)
            echo -e "${BLUE}Parando todos os serviços...${NC}"
            stop_rds
            stop_ec2
            echo -e "${GREEN}✓ Todos os serviços parados${NC}"
            ;;
        2)
            echo -e "${BLUE}Iniciando todos os serviços...${NC}"
            start_rds
            start_ec2
            echo -e "${GREEN}✓ Todos os serviços iniciados${NC}"
            ;;
        3)
            stop_ec2
            ;;
        4)
            start_ec2
            ;;
        5)
            stop_rds
            ;;
        6)
            start_rds
            ;;
        7)
            check_status
            ;;
        8)
            show_resource_info
            ;;
        9)
            echo -e "${GREEN}Saindo...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Opção inválida!${NC}"
            ;;
    esac
}

# Função principal
main() {
    show_banner
    
    # Verificar AWS CLI
    check_aws_cli
    echo -e "${GREEN}✓ AWS CLI configurado corretamente${NC}"
    echo ""
    
    # Loop principal do menu
    while true; do
        show_menu
        read -p "Escolha uma opção (1-9): " choice
        echo ""
        execute_option $choice
        echo ""
        read -p "Pressione Enter para continuar..."
        clear
        show_banner
    done
}

# Verificar se foi passado parâmetro para execução direta
if [ $# -eq 1 ]; then
    case $1 in
        "stop")
            show_banner
            check_aws_cli
            execute_option 1
            ;;
        "start")
            show_banner
            check_aws_cli
            execute_option 2
            ;;
        "status")
            show_banner
            check_aws_cli
            execute_option 7
            ;;
        *)
            echo -e "${RED}Parâmetro inválido. Use: stop, start ou status${NC}"
            exit 1
            ;;
    esac
else
    main
fi
