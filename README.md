# SriramMart – e-commerce platform (Buyer · Seller · Admin)

Java 17 · Spring Boot 3 (Spring MVC + Thymeleaf front end, Spring Security, JPA/Hibernate) · SQL database (H2, MySQL or Microsoft SQL Server)

The screens follow your mock-ups: login/register, home, deals, category listings with filters, product page with tabs,
cart, checkout, orders, wishlist, notifications, and the smiling-robot **SriramMart AI Assistant**.
Seller and admin consoles use the same theme and colours.

---------------------------------------------------------------------------------------------------

## 1. Run it (5 minutes)

Requirements: **JDK 17+** and **Maven 3.8+** (internet needed once so Maven can download the dependencies).

```bash
cd sriram-mart
mvn spring-boot:run          # or:  ./run.sh   (Windows: run.bat)
```

Open **http://localhost:8080** – the site opens at the login page. Nothing else to install: the default database is an
embedded H2 file database stored in `./data`. Demo data (products, customers, reviews, ~150 orders) is created on the first start.

### Demo accounts (change them before going live)

| Role   | Username             | Password      | Opens                    |
|--------|----------------------|---------------|--------------------------|
| Buyer  | `sriram`             | `Buyer@123`   | shop (cart, wishlist…)   |
| Seller | `sriramelectronics`  | `Seller@123`  | `/seller` console        |
| Admin  | `admin`              | `Admin@123`   | `/admin` console         |

Other sellers (`audioworld`, `pumaofficial`, `fireboltt`, `fitzone`, `stylehub`, `homenest`, `beautybay`, `toytown`, `booknook`,
`freshbasket`) use `Seller@123`. `gadgetzone` is a seller waiting for approval (approve it from Admin → Users).
The 60 generated demo customers (`firstname.lastname`) use `Demo@1234`.
Set `SEED_DEMO_DATA=false` to start with an empty store (only the admin account and categories are created).

## 2. Use SQL Server or MySQL instead of H2

1. Run the script for your database (creates the database, the **user id + password** for the app, and its permissions):
   * SQL Server → `db/sqlserver-setup.sql`     * MySQL → `db/mysql-setup.sql`
2. Edit the password in the script, then start the app with the same credentials:

```bash
# SQL Server
export SPRING_PROFILES_ACTIVE=sqlserver DB_USER=srirammart_app DB_PASS='YourStrongPassword'
# optional: DB_URL='jdbc:sqlserver://HOST:1433;databaseName=srirammart;encrypt=true;trustServerCertificate=true'
java -jar target/srirammart-1.0.0.jar

# MySQL
export SPRING_PROFILES_ACTIVE=mysql DB_USER=srirammart_app DB_PASS='YourStrongPassword'
java -jar target/srirammart-1.0.0.jar
```

Tables are created automatically. `db/useful-queries.sql` shows users, orders, order lines and live stock.

**Two different logins exist, both protected:**
* *Database login* (`srirammart_app` + password) – only the application server uses it.
* *Website login* – every page except login/register needs a website user id + password. Accounts live in the `users` table;
  passwords are stored only as BCrypt hashes.

## 3. What is stored automatically

* **Orders** (`orders`, `order_items`): every purchase is saved with buyer, address, payment method, totals, coupon and per-item status.
* **Stock**: placing an order runs `UPDATE products SET stock = stock - qty WHERE id = ? AND stock >= qty` inside the order transaction, so
  the last unit can never be sold twice; if any item fails the whole order rolls back. Cancelling an order puts stock back.
  Sellers/admins can also edit stock; low-stock warnings appear on the dashboards.
* Cart, wishlist, reviews (ratings update the product rating), notifications, coupons and their usage counts.

## 4. Security

* Form login with BCrypt (cost 10), session-fixation protection, HttpOnly + SameSite cookies, optional 14-day "remember me".
* Account lock for 15 minutes after 5 wrong passwords; password rule: 8+ chars with upper-case, lower-case and a digit.
* CSRF tokens on every form and AJAX call; strict Content-Security-Policy (no inline scripts), clickjacking protection.
* Role rules in `SecurityConfig`: `/admin/**` admin only, `/seller/**` sellers only, cart/checkout/orders/wishlist buyers only.
  New seller accounts must be approved by an admin before they can sign in.
* Product photo uploads are decoded and re-encoded (only real images are accepted), stored under random names in `./uploads`.
* All database access goes through JPA/prepared statements (no string-built SQL).

## 5. Interfaces

* **Buyer** – home, categories, deals, search, filters (category/brand/price/rating + specs such as RAM or Age group), product page
  (gallery, delivery date by pincode, offers, specs, reviews), cart with coupons, checkout, orders with tracking timeline and cancellation,
  wishlist, notifications, account/password.
* **Seller** (`/seller`) – sales dashboard, add/edit products with photo upload, stock updates, hide/show, fulfil orders (status changes notify the buyer).
* **Admin** (`/admin`) – KPIs and charts, users & seller approval, all products, all orders, coupons, **bulk CSV import**
  (`src/main/resources/data/products.csv` is the sample/format; import thousands of products at once).

## 6. AI assistant (smiling robot)

Type or tap a quick action in the chat window (bottom-right, or "Chat Now"). It is **not a scripted bot**:

1. The built-in engine understands the question and answers from the live database – product search with budgets ("laptop under 50000"),
   stock and price, specs of the product you are viewing, offers/coupons, your own orders ("track SM123456"), returns, payments, delivery.
2. If a language-model API is reachable, it rephrases the answer naturally using only that store data (`chatbot.api.*` in `application.properties`).

**Free API note:** I checked the free "no key" text endpoints in September 2026. Pollinations (the default configured here,
`https://gen.pollinations.ai/v1/chat/completions`) now asks for an API key, and no dependable key-less LLM API is available.
So the assistant works fully without any key using the built-in engine; the app tries the API automatically and falls back silently
(and pauses retries for a few minutes) when it answers 401/403/429 or is offline. To enable the language model, create a free key
and start the app with `CHATBOT_API_KEY=your_key`. Any OpenAI-compatible service also works via `CHATBOT_API_URL`, `CHATBOT_API_MODEL`.

## 7. Configuration (environment variables)

| Variable | Default | Meaning |
|---|---|---|
| `PORT` | 8080 | web port |
| `SPRING_PROFILES_ACTIVE` | – | `mysql` or `sqlserver` (default is H2) |
| `DB_URL`, `DB_USER`, `DB_PASS` | H2 file DB | database connection |
| `ADMIN_USERNAME`, `ADMIN_PASSWORD`, `ADMIN_EMAIL` | admin / Admin@123 | first admin (created only if none exists) |
| `SEED_DEMO_DATA` | true | create demo catalogue/customers/orders on first start |
| `UPLOAD_DIR` | ./uploads | seller photo folder (keep it on a persistent disk) |
| `REMEMBER_ME_KEY` | (placeholder) | **set a long random value in production** |
| `CHATBOT_API_KEY`, `CHATBOT_API_URL`, `CHATBOT_API_MODEL` | – / Pollinations / openai | optional LLM for the assistant |
| `THYMELEAF_CACHE` | true | set false while editing templates |

## 8. Deploy anywhere

* **Any server / Windows / Linux / VM:** `mvn package` → run `java -jar target/srirammart-1.0.0.jar` (put Nginx/Apache with HTTPS in front).
* **Docker + MySQL:** `cp .env.example .env` (edit passwords) → `docker compose up --build` → http://localhost:8080
* **Docker only:** `docker build -t srirammart . && docker run -p 8080:8080 -v sm-data:/app/data -v sm-uploads:/app/uploads srirammart`
* **PaaS (Azure App Service, Render, Railway, AWS Elastic Beanstalk…):** deploy the jar, set the environment variables above and point `DB_URL` to a managed database.

Production checklist: change all demo passwords, set `SEED_DEMO_DATA=false`, set `ADMIN_PASSWORD` and `REMEMBER_ME_KEY`, use HTTPS,
use MySQL/SQL Server (not H2), back up the database and the uploads folder.

## 9. Good to know

* **Product photos** were cut from the mock-ups you supplied (I had no internet access to download other photos). They are clean, but a few
  packaging photos contain the mock-up's own stylised/garbled label text. Replace any photo with a sharper one from **Seller → My Products → Edit**,
  or by editing the `image` column in the bulk-import CSV. Products whose photo did not match the mock-up name were renamed to match the photo
  (e.g. the "ASUS TUF" laptop photo shows a ROG logo, so it is listed as ROG Strix G15).
* The catalogue has 75 photographed products in 9 categories; add more with Admin → Bulk import.
* **Payments** use a built-in demo gateway (no real money, no card data stored). Connect Razorpay/Stripe/PayU in `CheckoutController`/`OrderService` before going live.
* "Continue with Google / Microsoft" buttons show a notice; enabling OAuth needs client credentials from those providers.
* Prices/discounts are kept consistent across pages (the mock-ups showed different MRPs for the same product on different pages).

## 10. Project map

```
src/main/java/com/srirammart
  config/   SecurityConfig, login lock-out listener, properties
  model/    JPA entities (User, Product, Order, OrderItem, CartItem, Review, Coupon, Notification …)
  repo/     Spring Data repositories (atomic stock UPDATE lives in ProductRepository)
  service/  CatalogService, OrderService, CartService, ChatService (AI), DashboardService, ProductService …
  web/      Controllers (buyer, seller, admin, chat API) and forms
  seed/     DataSeeder (first-start demo data)
src/main/resources
  templates/  Thymeleaf pages (fragments/layout.html holds header, sidebar, icons, chat)
  static/     css/app.css, js/app.js, js/chat.js, img/ (products, banners, logo, robot)
  data/       categories.csv, sellers.csv, products.csv
db/           SQL Server & MySQL setup scripts, useful queries
```
