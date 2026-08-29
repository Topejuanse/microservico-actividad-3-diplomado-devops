SCRIPTS := scripts

.PHONY: up down restart status password ui

up: ## Crea el cluster + Argo CD + microservicios
	bash $(SCRIPTS)/up.sh

down: ## Elimina el cluster local
	bash $(SCRIPTS)/down.sh

restart: down up ## Recrea el entorno desde cero

status: ## Muestra el estado del entorno
	bash $(SCRIPTS)/status.sh

password: ## Imprime la password inicial de admin de Argo CD
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo

ui: ## Abre un port-forward a la UI de Argo CD en http://localhost:8081
	@echo "Argo CD -> http://localhost:8081  (Ctrl+C para salir)"
	kubectl -n argocd port-forward svc/argocd-server 8081:80
