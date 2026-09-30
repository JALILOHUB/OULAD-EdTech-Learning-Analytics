# Data Quality SQL

Quality checks will cover:

- Completeness — اكتمال البيانات — Complétude
- Uniqueness — التفرد — Unicité
- Referential Integrity — سلامة العلاقات المرجعية — Intégrité référentielle
- Validity — الصلاحية — Validité
- Range Validation — التحقق من النطاق — Validation des plages
- Accepted Values — القيم المقبولة — Valeurs autorisées
- Temporal Consistency — الاتساق الزمني — Cohérence temporelle
- Volume Checks — فحوصات حجم البيانات — Contrôles de volume
- Outlier Detection — اكتشاف القيم الشاذة — Détection des valeurs aberrantes

Do not delete a record merely because a NULL, repeated ID or unusual value exists.
First determine whether it is valid for the table's grain and official definition.
