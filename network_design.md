# Diseño de Red y Planificación de Direcciones IP (CIDR)

Para la infraestructura de GreenDevCorp, se utilizará el bloque CIDR base `10.0.0.0/16` para toda la organización. A continuación se detalla la subdivisión de esta red y la justificación para cada entorno:

* **Development (`10.0.1.0/24`):** Esta subred permite hasta 254 direcciones IP. Es un rango suficiente para los entornos de prueba y el trabajo diario de los desarrolladores. * **Staging (`10.0.2.0/24`):** Entorno de pre-producción. Se separa a nivel de red para poder realizar pruebas fidedignas antes de lanzar a producción, manteniendo el entorno aislado.
* **Production (`10.0.3.0/24`):** El entorno real y en vivo. Debe estar estrictamente aislado de los demás entornos para garantizar que un fallo, prueba o brecha de seguridad en desarrollo no afecte a la disponibilidad de los usuarios finales. * **External Partners (`10.0.10.0/24`):** Una red separada para accesos temporales y controlados de colaboradores externos. Actúa como una capa de seguridad extra para que terceros no tengan acceso directo a las redes internas de la empresa.


