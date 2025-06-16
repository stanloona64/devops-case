Beyza Önal
onal.beyza@gmail.com

1. Cluster Oluşturulması (GKE)

Google Kubernetes Engine (GKE) kullanılarak, Avrupa bölgesinde (europe-west1) "caseenuygun" adındaki proje üzerinde "demo" isimli bir Kubernetes cluster oluşturuldu. "terraform-on-gcp-enuygun" isimli bucket'a bağlandı. Cluster, uygulama için yüksek performans ve esneklik sağlayacak şekilde konfigüre edildi.

![cluster](https://github.com/user-attachments/assets/9e91abb6-ff51-442e-a935-1c0ff4e50d54)

![bucket](https://github.com/user-attachments/assets/0081c747-e4dc-4c16-a25b-75d35d346790)


*Logging ve Monitoring

Cluster kurulumu sırasında logging ve monitoring özellikleri devre dışı bırakıldı.

Bu tercihle birlikte sistem kaynaklarının kullanımı azaltıldı, Prometheus ve Grafana gibi özelleştirilebilir çözümlere yer açıldı.

2. Node Pool Yapılandırması

Cluster içinde iki farklı node pool tanımlandı:

main-pool: sabit node sayısıyla (1), altyapı servisleri için.

application-pool: autoscaling destekli (1-3 node), uygulama yüklerini çalıştırmak için.

EK. VPC ve Subnet Yapılandırması
Terraform ile cluster için özel bir sanal ağ (VPC) ve alt ağ (subnet) yapılandırması yapıldı.
Bu yapılandırma ile otomatik subnet oluşturma kapatıldı ve özelleştirilmiş bir subnet tanımlandı.

Faydaları:

*Ağ izolasyonu: Uygulama trafiği, hizmet trafiği ve pod'lar için ayrı IP aralıkları tanımlanarak güvenli ve yönetilebilir bir altyapı oluşturuldu.

*GKE entegrasyonu: Cluster kurulumunda bu özel IP blokları doğrudan ip_range_pods ve ip_range_services parametrelerine bağlandı, böylece GKE ile tam uyum sağlandı.

*Ölçeklenebilirlik: Daha büyük IP aralıkları kullanılarak ileride yapılacak genişlemelere hazır bir ağ tasarlandı.

3. Uygulama Deploy'u

YAML manifest (nginx-deployment.yaml) ile basit bir nginx deployment yapıldı. Bu deployment yalnızca application-pool üzerinde çalışacak şekilde nodeSelector ile sınırlandı.

Faydası:

Donanım kaynakları daha verimli kullanılıyor.

Yük altındaki uygulamalar izolasyon sayesinde etkilenmiyor.

4. Horizontal Pod Autoscaler (HPA)

CPU kullanımı %25'i geçtiğinde nginx pod'unun 1'den 3'e kadar ölçeklenmesi için HPA tanımlandı. Bu da nginx-hpa.yaml deploy edilmesiyle sağlandı.

5. Prometheus & Grafana Kurulumu

Cluster'a kube-prometheus-stack Helm chart'ı ile Prometheus ve Grafana kuruldu.

Grafana LoadBalancer tipiyle dış erişime açıldı ve admin şifresi belirlendi.

![grafana-clusters](https://github.com/user-attachments/assets/1c1ccfc6-1ea3-4200-a7a4-523a6b7788bc)


6. Grafana Alarm

Grafana arayüzünden pod restart'larını izleyen bir alarm tanımlandı.

![alert](https://github.com/user-attachments/assets/7a46bedb-1fe1-4961-9ef5-2d61cb404ded)

Amaç:

Uygulama stabilitesini bozan durumları erkenden tespit etmek.

Proaktif hata müdahalesi sağlamak.

7. KEDA Kurulumu

KEDA Helm chart ile "keda" namespace altına deploy edildi.
KEDA ile de 1 - 3 pod arası scale işlemi gerçekleştirilebiliyor. Ancak bunun yapılabilmesi için HPA deaktive edilmesi gerekiyor onun yerine nginx-keda-scaler.yaml deploy edilmeli.

kubectl delete hpa nginx-hpa

kubectl apply -f nginx-keda-scaler.yaml

8. Istio Service Mesh

Istio bileşenleri helm üzerinden kuruldu:

*istio-base

*istiod (control plane)

*istio-ingressgateway (LoadBalancer tipi)

*istio-egressgateway (ClusterIP tipi)
