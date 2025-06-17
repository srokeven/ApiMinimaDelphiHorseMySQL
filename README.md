# Api Mínima Delphi + Horse + MySQL

Este projeto é uma **API mínima** desenvolvida em **Delphi** utilizando o framework **Horse**, com persistência de dados via **MySQL**. O foco é fornecer uma base simples, enxuta e funcional para aplicações de backend com suporte a execução como serviço no Linux.

---

## 🚀 Instalação no Linux (como serviço systemd)

### 1. Criar diretório do serviço

Crie a pasta onde o aplicativo e seus arquivos de configuração ficarão:

```sudo mkdir -p /opt/<nome-do-serviço>```

Substitua <nome-do-serviço> pelo identificador desejado (ex: apiminima).

### 2. Copiar arquivos do aplicativo
Coloque o executável e o arquivo .ini de configuração no diretório criado:

```sudo cp <aplicativo> <aplicativo>.ini /opt/<nome-do-serviço>/```

### 3. Ajustar permissões
Configure permissões apropriadas:

```sudo chmod -R 755 /opt/<nome-do-serviço>/```

⚠️ Atenção: O uso de chmod 777 é desaconselhado por questões de segurança.

### 4. Instalar o arquivo de serviço
Coloque o arquivo de definição do serviço em /etc/systemd/system/:

```sudo cp <NomeDaAplicacao>.service /etc/systemd/system/```

### 5. Ativar e iniciar o serviço

```sudo systemctl enable <NomeDaAplicacao>.service```
```sudo systemctl start <NomeDaAplicacao>.service```

Verifique o status com:
```sudo systemctl status <NomeDaAplicacao>.service```

🧩 Dependência: Biblioteca MySQL
Para que o binário funcione corretamente, é necessário instalar a biblioteca de cliente MySQL:

```sudo apt-get update```
```sudo apt-get install libmysqlclient20```

Crie um link simbólico, se necessário:

```sudo ln -s /usr/lib/x86_64-linux-gnu/libmysqlclient.so.20 /usr/lib/x86_64-linux-gnu/libmysqlclient.so```

📋 Pré-requisitos
Delphi com suporte a compilação para Linux (Delphi Rio 10.3 ou superior)

Framework Horse

MySQL Server instalado e acessível

Bibliotecas MySQL no sistema

📁 Estrutura sugerida do projeto

<pre>├── src/
│   └── main.dpr
├── config/
│   └── app.ini
├── systemd/
│   └── ApiMinimaDelphiHorse.service
├── README.md</pre>

📦 Exemplo de arquivo .service

<pre>[Unit]
Description=API Delphi Horse
After=network.target

[Service]
ExecStart=/opt/apiminima/apiminima
WorkingDirectory=/opt/apiminima
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target</pre>

🤝 Contribuição
Sinta-se à vontade para contribuir com sugestões, melhorias ou correções. Basta abrir uma issue ou enviar um pull request.

📄 Licença
Distribuído sob a licença MIT. Veja o arquivo LICENSE para mais informações.
