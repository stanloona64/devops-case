Beyza Önal
onal.beyza@gmail.com

1. Cluster Oluşturulması (GKE)

Google Kubernetes Engine (GKE) kullanılarak, Avrupa bölgesinde (europe-west1) "caseenuygun" adındaki proje üzerinde "demo" isimli bir Kubernetes cluster oluşturuldu. "terraform-on-gcp-enuygun" isimli bucket'a bağlandı. Cluster, uygulama için yüksek performans ve esneklik sağlayacak şekilde konfigüre edildi.

*Logging ve Monitoring

Cluster kurulumu sırasında logging ve monitoring özellikleri devre dışı bırakıldı.

Bu tercihle birlikte sistem kaynaklarının kullanımı azaltıldı, Prometheus ve Grafana gibi özelleştirilebilir çözümlere yer açıldı.

2. Node Pool Yapılandırması

Cluster içinde iki farklı node pool tanımlandı:

main-pool: sabit node sayısıyla (1), altyapı servisleri için.

application-pool: autoscaling destekli (1-3 node), uygulama yüklerini çalıştırmak için.

3. Uygulama Deploy'u

YAML manifest ile basit bir nginx deployment yapıldı. Bu deployment yalnızca application-pool üzerinde çalışacak şekilde nodeSelector ile sınırlandı.

Faydası:

Donanım kaynakları daha verimli kullanılıyor.

Yük altındaki uygulamalar izolasyon sayesinde etkilenmiyor.

4. Horizontal Pod Autoscaler (HPA)

CPU kullanımı %25'i geçtiğinde nginx pod'unun 1'den 3'e kadar ölçeklenmesi için HPA tanımlandı.

5. Prometheus & Grafana Kurulumu

Cluster'a kube-prometheus-stack Helm chart'ı ile Prometheus ve Grafana kuruldu.

Grafana LoadBalancer tipiyle dış erişime açıldı ve admin şifresi belirlendi.

6. Grafana Alarm

Grafana arayüzünden pod restart'larını izleyen bir alarm tanımlandı.

Amaç:

Uygulama stabilitesini bozan durumları erkenden tespit etmek.

Proaktif hata müdahalesi sağlamak.

7. KEDA Kurulumu

KEDA Helm chart ile "keda" namespace altına deploy edildi.

8. Istio Service Mesh

Istio bileşenleri helm üzerinden kuruldu:

*istio-base

*istiod (control plane)

*istio-ingressgateway (LoadBalancer tipi)

*istio-egressgateway (ClusterIP tipi)
