console.log("Phase 6 app.js loaded - agent mode");

async function loadKpis() {
  console.log("Loading KPIs...");

  try {
    const response = await fetch("/api/kpis");
    const data = await response.json();

    console.log("KPI response:", data);

    document.getElementById("total-sales").textContent = data.total_sales;
    document.getElementById("orders").textContent = data.orders;
    document.getElementById("returns-rate").textContent = data.returns_rate;
    document.getElementById("low-stock-items").textContent = data.low_stock_items;
  } catch (error) {
    console.error("Failed to load KPIs:", error);

    document.getElementById("total-sales").textContent = "Error";
    document.getElementById("orders").textContent = "Error";
    document.getElementById("returns-rate").textContent = "Error";
    document.getElementById("low-stock-items").textContent = "Error";
  }
}

function addMessage(type, text) {
  const chatWindow = document.getElementById("chat-window");

  if (!chatWindow) {
    console.error("chat-window element was not found");
    return null;
  }

  const message = document.createElement("div");
  message.className = `message ${type}`;
  message.textContent = text;

  chatWindow.appendChild(message);
  chatWindow.scrollTop = chatWindow.scrollHeight;

  return message;
}

function formatAgentResponse(data) {
  let responseText = data.answer || "No answer returned from Retail AI Agent.";

  if (data.route) {
    responseText += `\n\nRoute used: ${data.route}`;
  }

  if (data.genie_result && data.genie_result.sql) {
    responseText += "\n\nGenerated SQL:\n" + data.genie_result.sql;
  }

  if (data.rag_context && data.rag_context.length > 0) {
    responseText += "\n\nRAG context used:";

    data.rag_context.slice(0, 3).forEach((item, index) => {
      const sourceName = item.source_name || "Unknown source";
      const sourceType = item.source_type || "Unknown type";
      const chunkText = item.chunk_text || "";

      responseText += `\n\n${index + 1}. ${sourceName} (${sourceType})\n${chunkText}`;
    });
  }

  return responseText;
}

async function handleChatSubmit(event) {
  event.preventDefault();

  console.log("Agent form submitted");

  const input = document.getElementById("question-input");

  if (!input) {
    console.error("question-input element was not found");
    return;
  }

  const question = input.value.trim();

  if (!question) {
    return;
  }

  addMessage("user", question);
  input.value = "";

  const loadingMessage = addMessage("assistant", "Asking Retail AI Agent...");

  try {
    const response = await fetch("/api/agent/ask", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ question }),
    });

    const data = await response.json();

    console.log("Agent API response:", data);

    if (!loadingMessage) {
      return;
    }

    if (!response.ok) {
      loadingMessage.textContent =
        data.detail || data.error || "Something went wrong calling the Retail AI Agent.";
      return;
    }

    loadingMessage.textContent = formatAgentResponse(data);
  } catch (error) {
    console.error("Error calling Retail AI Agent:", error);

    if (loadingMessage) {
      loadingMessage.textContent = `Error calling Retail AI Agent: ${error}`;
    } else {
      addMessage("assistant", `Error calling Retail AI Agent: ${error}`);
    }
  }
}

document.addEventListener("DOMContentLoaded", () => {
  console.log("DOM fully loaded");

  loadKpis();

  const chatForm = document.getElementById("chat-form");

  if (!chatForm) {
    console.error("chat-form element was not found");
    return;
  }

  chatForm.addEventListener("submit", handleChatSubmit);

  console.log("Agent form event listener attached");
});