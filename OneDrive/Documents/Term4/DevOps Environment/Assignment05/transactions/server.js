const express = require("express");
const { MongoClient } = require("mongodb");
const cors = require("cors");

const app = express();
const PORT = process.env.PORT || 3000;
const MONGO_URI = process.env.MONGO_URI || "mongodb://mongo:27017";

app.use(cors());
app.use(express.json());

let db;

// Connect to MongoDB
MongoClient.connect(MONGO_URI)
  .then((client) => {
    console.log("Connected to MongoDB");
    db = client.db("bank_app");
  })
  .catch((error) => console.error("MongoDB connection error:", error));

// Get transactions grouped by month
app.get("/api/transactions/:email", async (req, res) => {
  try {
    const { email } = req.params;

    const transactions = await db
      .collection("transactions")
      .find({ email })
      .toArray();

    // Group transactions by month
    const groupedByMonth = transactions.reduce((acc, transaction) => {
      const date = new Date(transaction.timestamp);
      const monthYear = date.toLocaleString("en-US", {
        month: "long",
        year: "numeric",
      });

      if (!acc[monthYear]) {
        acc[monthYear] = [];
      }

      acc[monthYear].push({
        type: transaction.type,
        amount: transaction.amount,
        timestamp: transaction.timestamp,
      });

      return acc;
    }, {});

    res.json(groupedByMonth);
  } catch (error) {
    console.error("Error fetching transactions:", error);
    res.status(500).json({ error: "Failed to fetch transactions" });
  }
});

// Health check endpoint
app.get("/", (req, res) => {
  res.send("Transactions service is running");
});

app.listen(PORT, () => {
  console.log(`Transactions service running on port ${PORT}`);
});
